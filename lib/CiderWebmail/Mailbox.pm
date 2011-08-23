package CiderWebmail::Mailbox;

=head1 NAME

CiderWebmail::Mailbox

=head1 SYNOPSIS

    my $messages = $mailbox->list_messages_hash({uids => \@uids});
    my @uids = $mailbox->uids({filter => 'foo', sort => 'date'});
    my @uids = $mailbox->simple_search({searchfor => 'foo'});

=head1 DESCRIPTION

Represents an IMAP folder

=cut

use Moose;

use CiderWebmail::Message;
use CiderWebmail::Message::Search;
use Mail::Address;

=head1 ATTRIBUTES

=over

=item c

=item mailbox

=back

=cut

has c       => (is => 'ro', isa => 'Object');
has mailbox => (is => 'ro', isa => 'Str');

=head2 list_messages_hash

Returns a list of messages with from, subject and date.
Takes a list of uids or a sort order.

=cut

sub list_messages_hash {
    my ($self, $o) = @_;
    
    return $self->c->model('IMAPClient')->get_headers_hash($self->c, { mailbox => $self->mailbox, uids => $o->{uids}, headers => [qw/To From Subject Date/] });
}

=head2 uids({filter => 'searchme', sort => 'date'})

Returns the uids of the messages in this folder. Takes an optional filter and a sort order.

=cut

sub uids {
    my ($self, $o) = @_;

    if ($o->{filter}) {
        my $search = CiderWebmail::Message::Search->new({ c => $self->c });
        return $search->search({ filter => $o->{filter}, mailbox => $self->mailbox });
    } else {
        $self->c->model('IMAPClient')->get_folder_uids($self->c, { mailbox => $self->mailbox, sort => $o->{sort}, range => $o->{range} });
    }
}

=head1 AUTHORS

Mathias Reitinger <mathias.reitinger@loop0.org>
Stefan Seifert <nine@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
