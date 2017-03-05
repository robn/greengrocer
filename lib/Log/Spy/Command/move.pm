package Log::Spy::Command::move;

use Log::Spy -command;

use 5.014;
use warnings;
use strict;

sub abstract { "move/merge indexes" }

sub description { <<DESC }
Move/merge indexes. Copies the given index to the target dir and removes the
original. If no indexes are specified, all indexes except the current day's
indexes are moved.
DESC

sub usage_desc { "Usage: spy -d <index-dir> move [opts...] <target-index-dir> [indexes...]" }

sub opt_spec {
  return (
    [ "target|t=s" => "target index copy into named index. Use to merge multiple indexes into a single one" ],
    [ "force|f"    => "force move of an active index (ie today's)" ],
    [ "keep|k"     => "don't remove the original indexes. They will be left in <index-dir>/move and can be removed. This is useful for testing" ],
  );
}

sub validate_args {
  my ($self, $opts, $args) = @_;
  
  $self->usage_error("Expected a target index dir and at least one index to move!") unless @$args > 1;
}

use Lucy;
use Log::Spy::Log;
use Log::Spy::Schema;
use Path::Tiny;
use Date::Format qw(time2str);

sub execute {
  my ($self, $opts, $args) = @_;

  my ($index_dir) = @{$self->app->global_options->{indexdir}};

  my ($target_dir, @source_indexes) = @$args;

  my $today = time2str("%Y%m%d", time);

  if (@source_indexes) {
    unless ($opts->{force}) {
      my @today_indexes = grep { substr($_, 0, 8) == $today } @source_indexes;
      if (@today_indexes) {
        print STDERR <<EOF;
E: One or more indexes are for today's logs. Moving today's indexes could cause
confusion later because if new logs arrive you'll end up with multiple indexes
with the same name, which isn't recommended. If you really want to do this,
rerun move with the --force option.

Affected indexes: @today_indexes
EOF
        exit 1;
      }
    }

    my @missing_indexes = grep { ! path($index_dir, $_)->is_dir } @source_indexes;
      if (@missing_indexes) {
        print STDERR <<EOF;
E: One or more indexes don't exist: @missing_indexes
EOF
        exit 1;
    }
  }

  else {
    @source_indexes = map {
      my $basename = $_->basename;
      my $date = substr($basename, 0, 8);
      $date > 0 && $date != $today ? $basename : ();
    } path($index_dir)->absolute->children;
  }

  my %target_map;

  my $target_index = $opts->{target};
  if ($target_index) {
    %target_map = map { $_ => path($target_dir, $target_index)->absolute } @source_indexes;
  }

  else {
    my @existing_target_indexes = grep { path($target_dir, $_)->is_dir } @source_indexes;
    if (@existing_target_indexes) {
      print STDERR <<EOF;
E: Target indexes already exist. Move them out of the way, or use --target to
merge indexes into an existing target.

Affected indexes: @existing_target_indexes
EOF
      exit 1;
    }

    my $target_temp_dir = path($target_dir, "tmp");
    $target_temp_dir->remove_tree;
    $target_temp_dir->mkpath;

    %target_map = map { $_ => path($target_temp_dir, $_)->absolute } @source_indexes;
  }

  my $log = Log::Spy::Log->logger("move");

  for my $source_index (sort keys %target_map) {
    my $source_index_path = path($index_dir, $source_index);
    my $target_index_path = $target_map{$source_index};

    my $indexer = eval {
      Lucy::Index::Indexer->new(
        index  => $target_index_path,
        schema => Log::Spy::Schema::schema(),
        create => 1,
      );
    };
    if ($@) {
      warn "E: couldn't open new index in $target_index_path: $@\n";
      exit 1;
    }

    $log->("reindexing $source_index_path into $target_index_path");
    $indexer->add_index($source_index_path);

    $log->("optimizing $target_index_path");
    $indexer->optimize;

    $log->("committing $target_index_path");
    $indexer->commit;

    unless ($target_index) {
      $log->("moving $target_index_path to $target_dir");
      path($target_index_path)->move(path($target_dir, $target_index_path->basename));
    }

    unless ($opts->{keep}) {
      $log->("deleting original index $source_index_path");
      path($source_index_path)->remove_tree;
    }
  }

  path($target_dir, "tmp")->remove_tree;

  $log->("done");
}

1;
