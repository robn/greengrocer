package Log::Spy;

# ABSTRACT: A log collector and search engine

use App::Cmd::Setup -app;

use 5.014;
use warnings;
use strict;

sub usage_desc { "Usage: spy -d <index-dir> action [opts...] [args...]" }

sub global_opt_spec {
  return (
    [ "indexdir|d=s@" => "index location. Multiples possible, but most actions will only use the first one; see help on specific actions for more details.",
      { required => 1 } ],
  );
}

1;
