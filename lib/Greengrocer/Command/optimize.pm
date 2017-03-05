package Greengrocer::Command::optimize;

use Greengrocer -command;

use 5.014;
use warnings;
use strict;

sub abstract { "optimize indexes for search" }

sub description { <<DESC }
Optimizes a indexes for fast searching. Indexes can become fragmented after a
lot of writes, which can make searching slower. Optimizing reprocesses the log
lines into a new unfragmented index which takes less effort to search. It
usually won't make the index significantly smaller.

Optimizing an index can take a long time (minutes) and locks the index for
writing, so new log entries cannot be added. For this reason don't try to
optimize an active index (that is, today's) or you'll likely end up losing
incoming log lines.
DESC

sub usage_desc { "Usage: greengrocer -d <index-dir> optimize <indexes...>" }

sub validate_args {
  my ($self, $opts, $args) = @_;
  
  $self->usage_error("Expected at least one index to optimize!") unless @$args;
}

use Lucy;
use Greengrocer::Schema;
use Greengrocer::Log;
use Path::Tiny;

sub execute {
  my ($self, $opts, $args) = @_;

  my ($index_dir) = @{$self->app->global_options->{indexdir}};

  my $log = Greengrocer::Log->logger("optimize");

  for my $index (@$args) {
    my $indexer = eval {
      Lucy::Index::Indexer->new(
        index  => path($index_dir, $index),
        schema => Greengrocer::Schema::schema(),
      );
    };
    if ($@) {
      warn "E: couldn't open index $index, skipping\n";
      next;
    }

    $log->("optimizing $index");

    $indexer->optimize;
    $indexer->commit;
  }
}

1;
