#!/usr/bin/perl
use common::sense;
use autodie;

use ElasticSearch;

my $e = ElasticSearch->new( servers => '127.0.0.1:9200' );

$e->delete_index(index=>'ciderwebmail');
$e->create_index(
    index => 'ciderwebmail',
);
$e->put_mapping(
    index   => 'ciderwebmail',
    type    => 'bodypart',
    mapping => {
        properties  =>  {
            user   => { type => "string", index => "not_analyzed" },
            folder => { type => "string", index => "not_analyzed" },
            uid    => { type => "integer", index => "not_analyzed" },
            header => { type => "string" },
            data   => { type => "attachment" },
        }
    }
);



