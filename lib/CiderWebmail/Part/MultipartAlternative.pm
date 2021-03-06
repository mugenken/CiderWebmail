package CiderWebmail::Part::MultipartAlternative;

use Moose;

has chosen_alternative => (is => 'rw', isa => 'Object');

extends 'CiderWebmail::Part';

=head2 content_type()

returns the content type the CiderWebmail::Part Plugin can handle (just a stub, override in CiderWebmail::Part::FooBar)

=cut

sub content_type {
    return 'multipart/alternative';
}

before qw/render handler/ => sub {
    my ($self) = @_;

    my @parts = reverse($self->subparts);

    foreach(@parts) {
        my $part = CiderWebmail::Part->new({ c => $self->c, entity => $_, uid => $self->uid, parent_message => $self->parent_message, mailbox => $self->mailbox, path => $self->path, id => 0 })->handler;
        if ($part->renderable) {
            $self->chosen_alternative($part);
            last;
        }
    }

};

=head2 render()

render a multipart/alternative

=cut

sub render {
    my ($self) = @_;

    my $output = undef;
    $output = $self->chosen_alternative->render if $self->chosen_alternative;
    return ($output or '');
}

=head2 handler()

returns the 'handler' for the part: a CiderWebmail::Part::FooBar object that can be used to ->render the part.

=cut

sub handler {
    my ($self) = @_;

    return $self->chosen_alternative;
}

=head2 renderable()

returns true if the part is renderable.

=cut

sub renderable {
    return 1;
}

1;
