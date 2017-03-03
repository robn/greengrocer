package Greengrocer;
use App::Cmd::Setup -app;

use 5.014;
use warnings;
use strict;

sub usage_desc { "Usage: greengrocer -d <index-dir> action [opts...] [args...]" }

sub global_opt_spec {
  return (
    [ "indexdir|d=s@" => "index location. Multiple locations can be specified by separating them with a colon. Most actions will only use the first one; see help on specific actions for more details.",
      { required => 1 } ],
  );
}

1;
