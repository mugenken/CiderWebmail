use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use FindBin qw($Bin);

return plan skip_all => 'Set TEST_USER and TEST_PASSWORD to access a mailbox for these tests' unless $ENV{TEST_USER} and $ENV{TEST_PASSWORD};

$ENV{CIDERWEBMAIL_NODISCONNECT} = 1;

use Catalyst::Test 'CiderWebmail';
use HTTP::Request::Common;

my ($response, $c) = ctx_request POST '/', [
    username => $ENV{TEST_USER},
    password => $ENV{TEST_PASSWORD},
];

my $unix_time = time();

open my $testmail, '<', "$Bin/testmessages/ICAL.mbox";
my $message_text = join '', <$testmail>;
$message_text =~ s/icaltest-TIME/icaltest-$unix_time/gm;

$c->model('IMAPClient')->append_message($c, { mailbox => 'INBOX', message_text => $message_text });

eval "use Test::WWW::Mechanize::Catalyst 'CiderWebmail'";
if ($@) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst required';
    exit;
}

my $uname = getpwuid $UID;

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/' );
$mech->submit_form_ok({ with_fields => { username => $ENV{TEST_USER}, password => $ENV{TEST_PASSWORD} } });

$mech->get_ok( 'http://localhost/mailbox/INBOX?length=99999' );
$mech->follow_link_ok({ text => 'icaltest-'.$unix_time });

$mech->content_contains('<th colspan="2" class="heading">Bastille Day Party</th>', 'summary/summary');
$mech->content_contains('<td class="begin">1997-07-14, 17:00:00</td>', 'begin');
$mech->content_contains('<td class="end">1997-07-15, 03:59:59</td>', 'end');
$mech->content_contains('<td colspan="2">Description-first-line&lt;br /&gt;</td>', 'description');

$mech->get_ok( 'http://localhost/mailbox/INBOX?length=99999' );
my @messages = $mech->find_all_links( text_regex => qr{\Aicaltest-$unix_time\z});
ok((@messages == 1), 'messages found');
$mech->get_ok($messages[0]->url.'/delete', "Delete message");

done_testing();
