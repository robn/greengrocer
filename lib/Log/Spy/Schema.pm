package Log::Spy::Schema;

use 5.014;
use warnings;
use strict;

use Lucy;

sub schema {
  # {"pid":"4090299","timestamp":"2015-12-21T18:47:30.697022-05:00","program":"sloti30t15/calalarmd","host":"imap30","message":" processing alarms"}

  state $schema = do {
    my $s = Log::Spy::Schema::Schema->new;

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

package Log::Spy::Schema::Architecture {

use parent 'Lucy::Plan::Architecture';

use LucyX::Index::ZlibDocWriter;
use LucyX::Index::ZlibDocReader;

sub register_doc_writer {
  my ($self, $seg_writer) = @_;
  my $doc_writer = LucyX::Index::ZlibDocWriter->new(
    schema     => $seg_writer->get_schema,
    snapshot   => $seg_writer->get_snapshot,
    segment    => $seg_writer->get_segment,
    polyreader => $seg_writer->get_polyreader,
  );
  $seg_writer->register(
    api       => "Lucy::Index::DocReader",
    component => $doc_writer,
  );
  $seg_writer->add_writer($doc_writer);
}

sub register_doc_reader {
  my ( $self, $seg_reader ) = @_;
  my $doc_reader = LucyX::Index::ZlibDocReader->new(
    schema   => $seg_reader->get_schema,
    folder   => $seg_reader->get_folder,
    segments => $seg_reader->get_segments,
    seg_tick => $seg_reader->get_seg_tick,
    snapshot => $seg_reader->get_snapshot,
  );
  $seg_reader->register(
    api       => 'Lucy::Index::DocReader',
    component => $doc_reader,
  );
}

}

package Log::Spy::Schema::Schema {

use parent 'Lucy::Plan::Schema';

sub architecture {
  shift;
  return Log::Spy::Schema::Architecture->new(@_);
}

}

1
