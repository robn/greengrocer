package Log::Spy::Command::index;

use Log::Spy -command;

use 5.014;
use warnings;
use strict;

my $DEFAULT_HOURS = 24;

sub abstract { "add a file of log events to the index" }

sub description { <<DESC }
Adds a file of log events to the index.

Events are one JSON object per line. The format is described in the Log::Spy docs.
DESC

sub usage_desc { "Usage: spy -d <index-dir> index [opts...] <file...>" }

sub opt_spec {
  return (
    [ "hours|h=i" => "create new index within each day evern N hours [default: $DEFAULT_HOURS]",
      { default => $DEFAULT_HOURS } ],
  );
}

sub validate_args {
  my ($self, $opts, $args) = @_;
  
  $self->usage_error("Expected at least one file to index!") unless @$args;
}

use Cpanel::JSON::XS;
use Path::Tiny;
use Time::HiRes qw(gettimeofday tv_interval);
use Log::Spy::Schema;
use Log::Spy::Log;

sub execute {
  my ($self, $opts, $args) = @_;

  my ($index_dir) = @{$self->app->global_options->{indexdir}};

  my $roll_hours = $opts->{hours} % 24;

  my %indexers;
  my ($t_start, $t_add, $t_commit);
  my $n_items = 0;

  $t_start = [gettimeofday];

  for my $file (@$args) {
    open my $fh, '<', $file
      or warn "E: couldn't open '$file' for read: $!\n" and next;

    while (my $line = <$fh>) {
      my $data = eval { decode_json($line) };
      if ($@) {
        warn "E: malformed JSON: $line";
        next;
      }

      @$data{qw(program pid)} = delete($data->{syslogtag}) =~ m/^([^\[]+)(?:\[(\d+)\])?:$/;
      $data->{pid} //= '';

      unless ($data->{program}) {
        warn "E: malformed program in event: $line";
        next;
      }

      my ($y, $m, $d, $h) = $data->{timestamp} =~ m/^(\d+)-(\d+)-(\d+)T(\d+)/;
      unless (defined $y && defined $m && defined $d && defined $h) {
        warn "E: malformed timestamp in event: $line";
        next;
      }

      my $key = "$y$m$d";
      if ($roll_hours) {
        my $roll = int($h / $roll_hours);
        $key .= $roll >= 10 ? "_$roll" : "_0$roll";
      }

      ($indexers{$key} ||= Lucy::Index::Indexer->new(
          index  => path($index_dir, $key),
          schema => Log::Spy::Schema::schema(),
          create => 1,
      ))->add_doc($data);

      $n_items++;
    }

    close $fh;
  }

  return unless $n_items;

  $t_add = [gettimeofday];

  for my $indexer (values %indexers) {
    $indexer->commit;
  };

  $t_commit = [gettimeofday];

  my $e_add     = tv_interval($t_start, $t_add);
  my $e_commit  = tv_interval($t_add, $t_commit);

  my $r_add    = $e_add / $n_items;
  my $r_commit = $e_commit / $n_items;

  my $log = Log::Spy::Log->logger("index");
  $log->(sprintf "indexed %d lines [add %.3f (%.6f) commit %.3f (%.6f)]", $n_items, $e_add, $r_add, $e_commit, $r_commit);
}

1;
