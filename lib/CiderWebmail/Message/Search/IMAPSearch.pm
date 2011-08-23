package CiderWebmail::Message::Search::IMAPSearch;
use Moose;

has c           => (is => 'ro', isa => 'Object', required => 1);

sub search {
    my ($self, $o) = @_;

    return $self->c->model('IMAPClient')->simple_search($self->c, { mailbox => $o->{mailbox}, filter => $o->{filter}, sort => $o->{sort} })
}

sub priority {
    return 1;
}

1;
