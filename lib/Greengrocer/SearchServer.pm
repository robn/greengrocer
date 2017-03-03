package Greengrocer::SearchServer;

use warnings;
use strict;

use Module::Runtime qw(use_module);
use Lucy;
use Greengrocer::Search;

our ($index_dir, $log);

sub psgi {
  my ($class, %args) = @_;

  $index_dir = $args{indexdir};
  $log = $args{logger} // sub {};

  use_module("Atto");

  Atto->import(qw(search));
  Atto->psgi;
}

sub collect_terms {
  my ($q) = @_;
  if ($q->isa("Lucy::Search::NoMatchQuery") || $q->isa("Lucy::Search::NOTQuery")) {
    return ();
  }
  elsif ($q->isa("Lucy::Search::PolyQuery")) {
    return keys %{ +{ map { $_ => 1 } map { collect_terms($_) } @{$q->get_children} } };
  }
  elsif ($q->isa("Lucy::Search::TermQuery")) {
    return ($q->get_term)
  }
  elsif ($q->isa("Lucy::Search::PhraseQuery")) {
    return @{$q->get_terms};
  }
  else {
    warn "collect_terms: don't know how to dump ".ref $q."\n";
    return ();
  }
}

sub search {
  my (%args) = @_;

  my $info = join(' ', map { ($args{$_} // '') ne '' ? "$_=$args{$_}" : () } qw(query start end));
  my $collector;

  my $error;

  my ($query, $start, $end, @collectors) = Greengrocer::Search::run_search(
    indexdir  => $index_dir,
    start     => $args{start},
    end       => $args{end},
    query     => $args{query},
    collector => sub {
      Greengrocer::SearchServer::Collector->new(searcher => shift);
    },
    error => sub {
      my ($msg) = @_;
      $log->("search: $info [FAILED: $msg]");
      $error = $msg;
    },
  );

  my @terms = collect_terms($query);

  my $matches = [ map { @{$_->matches} } @collectors ];
  my $count = @$matches;

  $log->(sprintf "search: %s [matches=%d]", $info, $count);

  return {
    start   => $start,
    end     => $end,
    query   => $args{query},
    terms   => \@terms,
    matches => $matches,
    count   => $count,
    ($error ? (error => $error) : ()),
  };
}

package Greengrocer::SearchServer::Collector {

use parent qw(Lucy::Search::Collector);

our %self;

sub new {
  my ($class, %args) = @_;

  my $ref = $class->SUPER::new;

  $self{$ref} = {
    searcher => $args{searcher},
    base     => 0,
    matches  => [],
  };

  return $ref;
}

sub matches {
  my ($ref) = @_;
  my $self = $self{$ref};
  $self->{matches};
}

sub DESTROY {
  my ($ref) = @_;
  my $self = delete $self{$ref};
}

sub collect {
  my ($ref, $doc_id) = @_;
  my $self = $self{$ref};
  my $doc = $self->{searcher}->fetch_doc($self->{base} + $doc_id);
  push @{$self->{matches}}, { map { $_ => $doc->{$_} } qw(timestamp host program pid message) };
}

sub set_base {
  my ($ref, $base) = @_;
  my $self = $self{$ref};
  $self->{base} = $base;
}

sub need_score { 0 }

}

1;
