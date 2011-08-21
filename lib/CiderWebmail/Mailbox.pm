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
use Mail::Address;
use ElasticSearch;

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

    return $o->{filter}
        ? $self->fulltext_search($o)
        #? $self->c->model('IMAPClient')->simple_search($self->c, { mailbox => $self->mailbox, searchfor => $o->{filter}, sort => $o->{sort} })
        : $self->c->model('IMAPClient')->get_folder_uids($self->c, { mailbox => $self->mailbox, sort => $o->{sort}, range => $o->{range} });
}

###TODO this is here just for testing
sub fulltext_search {
    my ($self, $o) = @_;

    my $e = ElasticSearch->new( servers => '127.0.0.1:9200' );

    warn "[DEBUG] ElasticSearch for $o->{filter} in ".$self->mailbox." for user ".$self->c->user->id;
    
    my $response = $e->search(
        index   => 'ciderwebmail',
        type    => 'bodypart',
        fields  => ['user', 'folder', 'uid', 'header'],
        query   => { field => { _all => $o->{filter} } },
        filterb => { user => $self->c->user->id, folder => $self->mailbox },
    );

    use Data::Dump qw/pp/;
    pp $response;

    my @uids;
    warn "[DEBUG] ElasticSearch got ".$response->{hits}->{total}." hits";

    foreach(@{ $response->{hits}->{hits} }) {
        warn "[DEBUG] Search Result: UID: $_->{fields}->{uid} FOLDER: $_->{fields}->{folder} SCORE: $_->{_score}";
        push(@uids, $_->{fields}->{uid});
    }

    return wantarray ? @uids : \@uids;
}

=head1 AUTHORS

Mathias Reitinger <mathias.reitinger@loop0.org>
Stefan Seifert <nine@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
