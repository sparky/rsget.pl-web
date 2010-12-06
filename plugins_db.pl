#!/usr/bin/perl
#
use strict;
use warnings;
use DBI;
use Digest::MD5 qw(md5_hex);

my $dbfile = "rsget.pl/download/plugins.sqlite3.db";
unlink $dbfile;

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );

$dbh->begin_work();
$dbh->do(
"CREATE TABLE plugins(
	name	VARCHAR(30),
	md5	CHAR(32),
	body	TEXT
)"
);

my $sth = $dbh->prepare( "INSERT INTO plugins( name, md5, body ) VALUES( ?, ?, ? )" );

chdir "svn";
foreach my $dir ( qw(Premium Get Video Audio Image Link Direct) ) {
	foreach my $name ( glob "$dir/*" ) {
		local $/ = undef;

		open my $fin, "<", $name;
		my $data = <$fin>;
		close $fin;

		my $md5 = md5_hex( $data );

		$sth->execute( $name, $md5, $data );
	}
}

$sth = undef;

$dbh->commit();

$dbh->do( "vacuum" );
$dbh->disconnect();
