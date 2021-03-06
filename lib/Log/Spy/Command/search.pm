package Log::Spy::Command::search;

use Log::Spy -command;

use 5.014;
use warnings;
use strict;

my $DEFAULT_START = "today";
my $DEFAULT_END   = "tomorrow";

sub abstract { "show log lines matching a query" }

sub description { <<DESC }
Searches for log lines matching the given query.
DESC

sub usage_desc { "Usage: spy -d <index-dir> search [opts...] <query...>" }

sub opt_spec {
  return (
    [ "start|s=s"   => "start date to search (inclusive) [default: $DEFAULT_START]",
      { default => $DEFAULT_START }],
    [ "end|e=s"     => "end date to search (exclusive) [default: $DEFAULT_END]",
      { default => $DEFAULT_END }],
    [ "json|j"      => "JSON output" ],
  );
}

sub validate_args {
  my ($self, $opts, $args) = @_;

  $self->usage_error("Expected some query terms!") unless @$args;
}

use Log::Spy::Search;

sub execute {
  my ($self, $opts, $args) = @_;

  Log::Spy::Search::run_search(
    index_dir => $self->app->global_options->{indexdir},
    start     => $opts->{start},
    end       => $opts->{end},
    query     => join(' ', @$args),
    collector => sub {
      Log::Spy::Command::search::Collector->new(searcher => shift, json => !!$opts->{json}),
    },
    error => sub {
      my ($msg) = @_;
      say STDERR "E: $msg";
    },
  );
}

package Log::Spy::Command::search::Collector {

use parent qw(Lucy::Search::Collector);
use Cpanel::JSON::XS;

our %self;

sub new {
  my ($class, %args) = @_;

  my $ref = $class->SUPER::new;

  $self{$ref} = {
    searcher => $args{searcher},
    base     => 0,
    json     => $args{json},
  };

  return $ref;
}

sub DESTROY {
  my ($ref) = @_;
  my $self = delete $self{$ref};
  if ($self->{json}) {
    if ($self->{started}) {
      say "\n]";
    }
    else {
      say "[]";
    }
  }
}

sub _output_text {
  my ($self, $doc) = @_;
  my ($timestamp, $host, $program, $pid, $message) = map { $doc->{$_} } qw(timestamp host program pid message);
  $pid = "[$pid]" if $pid;
  printf "%s %s %s%s:%s\n", $timestamp, $host, $program, $pid, $message;
}

sub _output_json {
  my ($self, $doc) = @_;

  unless ($self->{started}) {
    say '[';
    $self->{started} = 1;
  }
  else {
    say ',';
  }

  print '  ', encode_json({ map { $_ => $doc->{$_} } qw(timestamp host program pid message) });
}

sub collect {
  my ($ref, $doc_id) = @_;
  my $self = $self{$ref};
  my $doc = $self->{searcher}->fetch_doc($self->{base} + $doc_id);
  if ($self->{json}) {
    _output_json($self, $doc);
  }
  else {
    _output_text($self, $doc);
  }
}

sub set_base {
  my ($ref, $base) = @_;
  my $self = $self{$ref};
  $self->{base} = $base;
}

sub need_score { 0 }

}

1;
