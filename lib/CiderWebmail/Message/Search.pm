package CiderWebmail::Message::Search;

use Moose;

has c           => (is => 'ro', isa => 'Object', required => 1);

use Carp qw/ carp confess /;
use Module::Pluggable require => 1, search_path => [__PACKAGE__];

has backends    => (is => 'rw', isa => 'HashRef', default => sub{ {} });

=head1 NAME

CiderWebmail::Message::Search - search for messages on varous backends

=cut

sub BUILD {
    my ($self) = @_;

    #TODO this needs to be improved... some backends will be better
    #TODO when searching for various things - select the best one depending
    #TODO on search criteria

    foreach(__PACKAGE__->plugins())  {
        warn "[DEBUG] Search Backend $_ loaded with Priority ".$_->priority;
        $self->backends->{$_->priority} = $_;
    }
}

sub search {
    my ($self, $o) = @_;

    confess("no search filter passed to Search->search()") unless defined $o->{filter};
    confess("no mailbox passed to Search->search()") unless defined $o->{mailbox};

    my @backends = sort(keys(%{ $self->backends}));

    my $backend = $self->backends->{$backends[-1]}->new(c => $self->c);

    return $backend->search($o);
}

1;
