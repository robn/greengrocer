package Greengrocer::Log;

use warnings;
use strict;

use Date::Format qw(time2str);

sub logger {
  my ($class, $action) = @_;
  return sub { print STDERR format_log($action, shift) };
};

sub format_log {
  return sprintf "[greengrocer:%s %s] %s %s\n", shift, $$, time2str("%Y-%m-%dT%H:%M:%S", time), shift;
}

1;
