package CiderWebmail::Model::IMAPClient;

use strict;
use warnings;
use parent 'Catalyst::Model';

use Mail::IMAPClient;

use MIME::Words qw/ decode_mimewords /;
use MIME::Parser;

use CiderWebmail::Message;
=head1 NAME

CiderWebmail::Model::IMAPClient - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=cut

sub folders {
    my ($self, $c) = @_;
    return $c->stash->{imap}->folders;
}

#select mailbox
sub select {
    my ($self, $c, $o) = @_;

    die unless $o->{mailbox};

    return $c->stash->{imap}->select($o->{mailbox});
}

#all messages in a mailbox
sub messages {
    my ($self, $c, $o) = @_;

    die unless $o->{mailbox};

    $self->select($c, { mailbox => $o->{mailbox} } );

    my @messages = ();
 
    foreach ( $c->stash->{imap}->search("ALL") ) {
        if ( $@ ) {
            die("error in imap search: $@");
        }
        my $uid = $_;
        push(@messages, CiderWebmail::Message->new($c, { uid => $uid, mailbox => $o->{mailbox} } ));
    }

    return \@messages;
}

#fetch a single message
sub message {
    my ($self, $c, $o) = @_;

    return CiderWebmail::Message->new($c, { uid => $o->{uid}, mailbox => $o->{mailbox} } );
}

sub decode_header {
    my ($self, $c, $o) = @_;

    die unless $o->{header};

    my $header;

    foreach ( decode_mimewords( $o->{header} ) ) {
        if ( @$_ > 1 ) {
            my $converter = Text::Iconv->new($_->[1], "utf-8");
            $header .= $converter->convert( $_->[0] );
        } else {
            $header .= $_->[0];
        }
    }

    return $header;
}

#fetch from server
sub get_header {
    my ($self, $c, $o) = @_;
   
    die unless $o->{mailbox};
    die unless $o->{uid};
    die unless $o->{header};

    $self->select($c, { mailbox => $o->{mailbox} } );

    my $header;

    if ( $o->{cache} ) {
        unless ( $c->stash->{headercache}->get({ uid => $o->{uid}, header => $o->{header} }) ) {
            $c->stash->{headercache}->set({ uid => $o->{uid}, header => $o->{header}, data => $c->stash->{imap}->get_header($o->{uid}, $o->{header}) });
        }

        $header = $c->stash->{headercache}->get({ uid => $o->{uid}, header => $o->{header} });
    } else {
        $header = $c->stash->{imap}->get_header($o->{uid}, $o->{header});
    }

    if ( $o->{decode} ) {
        return $self->decode_header($c, { header => $header });
    } else {
        return $header;
    }
}

sub date {
    my ($self, $c, $o) = @_;

    die("mailbox not set") unless( defined($o->{mailbox} ) );
    die("uid not set") unless( defined($o->{uid}) );
    
    my $date = $self->get_header($c,  { header => "Date", uid => $o->{uid}, mailbox => $o->{mailbox} } );
    
    if ( defined($date) ) {
        #some mailers specify (CEST)... Format::Mail isn't happy about this
        #TODO better solution
        $date =~ s/\([a-zA-Z]+\)$//;

        my $dt = DateTime::Format::Mail->new();
        $dt->loose;

        return $dt->parse_datetime($date);
    }
}

sub body {
    my ($self, $c, $o) = @_;

    die("mailbox not set") unless( defined($o->{mailbox} ) );
    die("uid not set") unless( defined($o->{uid}) );

    $self->select($c, { mailbox => $o->{mailbox} } );

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    my $entity = $parser->parse_data( $c->stash->{imap}->body_string( $o->{uid} ) );

    #don't rely on this.. it will change once we support more advanced things
    return join('', @{ $entity->body() });
}

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
