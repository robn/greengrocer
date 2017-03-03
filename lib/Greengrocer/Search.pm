package Greengrocer::Search;

use 5.014;
use warnings;
use strict;

use Greengrocer::Schema;

use Lucy;
use Path::Tiny;
use Date::Format qw(time2str);
use Date::Parse qw(str2time);

sub run_search {
  my (%args) = @_;

  my $query_parser = Lucy::Search::QueryParser->new(
    schema         => Greengrocer::Schema::schema(),
    default_boolop => 'AND',
  );
  $query_parser->set_heed_colons(1);
  my $query = $query_parser->parse($args{query} // '');

  my $now = time;
  my $start_date = time2str("%Y%m%d", str2time($args{start}) // $now);
  my $end_date   = time2str("%Y%m%d", str2time($args{end}) // ($now+86400));
  if ($start_date ge $end_date) {
    $args{error}->("invalid date range $start_date - $end_date");
    return ($query, $start_date, $end_date);
  }

  my @indexes =
    grep {
      my ($basename) = $_->basename =~ m/^(\d+)/;
      $basename //= -1;
      $basename >= $start_date && $basename < $end_date;
    } map {
      path($_)->absolute->children
    } @{$args{indexdir}};

  my @searchers = map { Lucy::Search::IndexSearcher->new(index => $_) } @indexes;

  my @collectors = map {
    my $searcher = $_;
    my $collector = $args{collector}->($searcher);
    $searcher->collect(
      query => $query,
      collector => $collector,
    );
    $collector;
  } @searchers;

  return ($query, $start_date, $end_date, @collectors);
}

1;
