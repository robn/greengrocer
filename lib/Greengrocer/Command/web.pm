package Greengrocer::Command::web;
use Greengrocer -command;

use 5.014;
use warnings;
use strict;

my $DEFAULT_PORT = 5515;

sub abstract { "run the web search API server" }

sub description { <<DESC }
Starts the web search API server. The agent itself will log info about its
activities to standard error.

To run a search, make a web request to the /search endpoint with the following
query parameters:

    start - start date to search (inclusive) [default: today]
    end   - end date to search (exclusive) [default: tomorrow]
    query - query string

Example:

    \$ curl http://127.0.0.1:5515/search?query=info
DESC

sub usage_desc { "Usage: greengrocer -d <index-dir> web [opts...]" }

sub opt_spec {
  return (
    [ "listen|l=s"   => "IP address to listen on [default: all]",
      { default => "0.0.0.0" } ],
    [ "port|p=i"     => "port to listen on [default: $DEFAULT_PORT]",
      { default => $DEFAULT_PORT } ],
  );
}

use Module::Runtime qw(use_module);
use Greengrocer::Log;
use Greengrocer::SearchServer;

sub execute {
  my ($self, $opts, $args) = @_;

  my $indexdir = $self->app->global_options->{indexdir};

  use_module($_) for qw(Starlet::Server Plack::Builder Plack::Middleware::Redirect Plack::Middleware::Deflater);

  my $server = Starlet::Server->new(host => $opts->{ip}, port => $opts->{port});

  my $log = Greengrocer::Log->logger("web");

  my $builder = Plack::Builder->new;
  $builder->add_middleware('Redirect', url_patterns => [ '^/$' => ['/ui/', 302] ]);
  $builder->add_middleware('Deflater');
  $builder->add_middleware('ContentLength');
  $builder->add_middleware('Static', path => sub { s{^/ui/$}{/ui/index.html}; m{^/ui/} }, root => './');
  $builder->mount('/', 
    Greengrocer::SearchServer->psgi(indexdir => $indexdir, logger => $log)
  );

  $server->run($builder->to_app);
}

1;
