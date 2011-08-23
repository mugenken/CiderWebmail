package CiderWebmail::Message::Search::ElasticSearch;
use Moose;

has c           => (is => 'ro', isa => 'Object', required => 1);

use ElasticSearch;
use Mail::IMAPClient::MessageSet;

sub search {
    my ($self, $o) = @_;

    my $e = ElasticSearch->new( servers => '127.0.0.1:9200' );

    warn "[DEBUG] ElasticSearch for $o->{filter} in ".$o->{mailbox}." for user ".$self->c->user->id;
    
    my $response = $e->search(
        index   => 'ciderwebmail',
        type    => 'bodypart',
        fields  => ['user', 'folder', 'uid', 'header'],
        query   => { field => { _all => $o->{filter} } },
        filterb => { user => $self->c->user->id, folder => $o->{mailbox} },
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


sub priority {
    
    #TODO check if ElasticSearch is actually online
    return 99;
}

1;
