#!/usr/bin/perl
use common::sense;
use autodie;

use ElasticSearch;
use Data::Dump qw{pp};

my $e = ElasticSearch->new( servers => '127.0.0.1:9200' );

pp $e->search(
    index   => 'ciderwebmail',
    type    => 'bodypart',
    fields  => ['user', 'folder', 'uid', '_source'],
    #query   => { field => { _all => 'iphone' } },
    queryb => {
        -filter => { user => 'cw', folder => 'INBOX', uid => 155 }
    }
);
