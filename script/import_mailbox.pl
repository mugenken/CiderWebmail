#!/usr/bin/perl
use common::sense;
use autodie;

use Data::Dump qw(pp); 

use ElasticSearch;
use Mail::IMAPClient;
use MIME::Base64;

my $user = $ARGV[0];
my $pass = $ARGV[1];

my $imap = Mail::IMAPClient->new(
    Server   => 'localhost',
    User     => $user,
    Password => $pass,
    Ssl      => 0,
    Uid      => 1,
) || die;

$imap->login();

$imap->select('INBOX');

my $e = ElasticSearch->new( servers => '127.0.0.1:9200' );

my $msgs = $imap->search("ALL");
foreach(@$msgs) {
    my $uid = $_;
    print "[DEBUG] Processing $uid\n";
    my $struct = $imap->get_bodystructure( $uid );

    my $parts = {};

    $parts->{$struct->id} = { type => lc($struct->bodytype."/". $struct->bodysubtype), enc => $struct->bodyenc };

    foreach($struct->bodystructure) {
        $parts->{$_->id} = { type => lc($_->bodytype."/". $_->bodysubtype), enc => $_->bodyenc };
    }

    my $result = $e->search(
        index => 'ciderwebmail',
        type  => 'bodypart',
        fields  => ['user', 'folder', 'uid'],
        queryb => {
            -filter => { user => 'cw', uid => $uid, folder => 'INBOX' }
        }
    );
    
    if ($result->{hits}->{total} > 0) {
        print "Alreay Indexed this!\n";
        next;
    }

    my @content;
    while(my ($id, $data) = each(%$parts)) {
          print "[DEBUG] $id\t$data->{type}\t$data->{enc}\n";

          next unless ($data->{type} =~ m[(text/plain|application/msword|application/pdf)]);
 
          my $string;
          if ($data->{enc} eq 'base64') {
             $string = decode_base64($imap->bodypart_string($uid, $id));
         } else {
             $string = $imap->bodypart_string($uid, $id);
         }

         push(@content, $string);
     }

     my $fetched_headers = $imap->parse_headers($uid, "ALL");
     my $header = "";

    while (my ($headername, $headervalue) = each(%$fetched_headers)) {
        $headervalue = join("\n", @$headervalue);
        $header .= join("", $headername, ": ", $headervalue, "\n");
    }

    $header .= $imap->fetch_hash($uid, "BODY.PEEK[HEADER.FIELDS (From To Subject Date)]")->{$uid}->{'BODY[HEADER.FIELDS (FROM TO SUBJECT DATE)]'};

     pp $e->index(
            index => 'ciderwebmail',
            type  => 'bodypart',
            data => {
                uid => $uid,
                folder => 'INBOX',
                user => 'cw',
                header => $header,
                file => \@content,
            },
         );

}
