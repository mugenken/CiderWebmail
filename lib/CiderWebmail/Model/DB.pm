package CiderWebmail::Model::DB;

use Moose;

extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'CiderWebmail::DB',
    connect_info => [
        'dbi:SQLite:root/var/user_settings.sql',
        
    ],
);

after BUILD => sub {
    my ($self, $c) = @_;

    my $dbh = $self->storage->dbh;

    my $db_version = $dbh->table_info(undef, undef, 'db_version', 'TABLE')->fetchall_arrayref;
    
    unless (@$db_version) {
        $dbh->do('create table db_version (version int not null primary key default 0)');
        $dbh->do('insert into db_version values (0)');
    }

    my $version = $dbh->selectrow_array('select version from db_version');

    if ($version < 1) {
        print STDERR "upgrading database schema to version 1\n";
        $dbh->do('create table addressbook (id INTEGER PRIMARY KEY, user varchar not null, firstname varchar not null, surname varchar not null, email varchar not null)');
        $dbh->do('update db_version set version = 1');
    }

    return $self;
};

=head1 NAME

CiderWebmail::Model::DB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<CiderWebmail>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<CiderWebmail::DB>

=head1 AUTHOR

Stefan Seifert

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
