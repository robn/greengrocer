package Log::Spy::Schema;

use 5.014;
use warnings;
use strict;

use Lucy;

sub schema {
  # {"pid":"4090299","timestamp":"2015-12-21T18:47:30.697022-05:00","program":"sloti30t15/calalarmd","host":"imap30","message":" processing alarms"}

  state $schema = do {
    my $s = Lucy::Plan::Schema->new;

    $s->spec_field(
      name => 'timestamp',
      type => Lucy::Plan::StringType->new(
        sortable => 1,
      ),
    );
    $s->spec_field(
      name => 'host',
      type => Lucy::Plan::StringType->new,
    );
    $s->spec_field(
      name => 'program',
      type => Lucy::Plan::FullTextType->new(
        analyzer => Lucy::Analysis::StandardTokenizer->new,
      ),
    );
    $s->spec_field(
      name => 'pid',
      type => Lucy::Plan::StringType->new,
    );
    $s->spec_field(
      name => 'message',
      type => Lucy::Plan::FullTextType->new(
        analyzer => Lucy::Analysis::StandardTokenizer->new,
      ),
    );

    $s;
  };

  return $schema;
}

1
