#!/usr/bin/perl
#
use strict;
use warnings;
use XML::LibXSLT;
use XML::LibXML;
use File::Path qw(make_path remove_tree);

$ENV{TZ} = "UTC";
$ENV{LANG} = "en_GB.UTF-8";
$ENV{LANGUAGE} = "en_GB";


my $html_files_dir = "/download";
my $files_dir = "src$html_files_dir";

my $xslt = XML::LibXSLT->new();
my $style_doc = XML::LibXML->load_xml(
	location => 'templates/changelog.xslt',
	no_cdata => 1
);
my $stylesheet = $xslt->parse_stylesheet( $style_doc );

sub xslt_fixlog
{
	local $_ = shift || die;
	s/^\s+//;
	s/\s+$//;
	return $_;
}

sub xslt_isgetter
{
	local $_ = shift || die;

	if ( m#^/toys/rsget\.pl/((Get|Video|Audio|Image|Link|Direct)/\S+)# ) {
		return 1 if -r "svn/$1";
	}

	return undef;
}


XML::LibXSLT->register_function( "urn:perl", "fixlog", \&xslt_fixlog );
XML::LibXSLT->register_function( "urn:perl", "isgetter", \&xslt_isgetter );


sub xml_changelog
{
	my $rev1 = shift || "HEAD";
	my $rev2 = shift || "0";
	$rev2++;

	open my $log, "-|", qw(svn log svn/ --xml -g -v -r), "$rev1:$rev2";

	my $source = XML::LibXML->load_xml( IO => $log );
	my $results = $stylesheet->transform( $source );

	my $out = $stylesheet->output_as_chars( $results );
	$out =~ s/^.*<html.*?>\n//s;
	$out =~ s{</html>.*$}{}s;
	return $out;
}


my $need_regen = 0;
my %list_files;
my %list_chlog;

opendir D_IN, $files_dir;
while ( $_ = readdir D_IN ) {
	if ( /^rsget\.pl-(\d+)\.tar/ ) {
		$list_files{ $1 } = $_;
	} elsif ( /^r(\d+)$/ ) {
		$list_chlog{ $1 } = $_;
	}
}
closedir D_IN;

foreach ( keys %list_files ) {
	unless ( exists $list_chlog{ $_ } ) {
		$need_regen = 1;
		last;
	}
}
if ( scalar keys %list_files != scalar keys %list_chlog ) {
	$need_regen = 1;
}

my @revisions = sort { $b <=> $a } keys %list_files;

{
	open my $f_out, ">", "$files_dir/latest.php";
	print $f_out "<?php\nheader( 'Location: $html_files_dir/$list_files{ $revisions[ 0 ] }' );\n?>\n";
	close $f_out;
}

sub page_changelog
{
	my $name = shift;
	my $page_head = shift;
	my $rev1 = shift;
	my $rev2 = shift;

	my $dir = "$files_dir/$name";
	print "Writing $dir\n";
	make_path( $dir );
	open my $f_out, ">", "$dir/index.xml";
	print $f_out $page_head;
	print $f_out xml_changelog( $rev1, $rev2 );
	close $f_out;
}

my $svn_head =
'index:	-999999
title:	svn
desc:	
	<ul>	
		<li>Get latest copy:
			<pre>svn co http://svn.pld-linux.org/svn/toys/rsget.pl</pre>
		</li>
		<li>SVN snapshot: <a href="/download/snapshot">latest svn tar</a></li>
	</ul>

body:	

	<h2>SVN changelog</h2>
';


page_changelog( 'svn', $svn_head, undef, $revisions[ 0 ] );

exit 0 unless $need_regen;

foreach my $name ( values %list_chlog ) {
	my $dir = "$files_dir/$name";
	print "Removing $dir\n";
	remove_tree( $dir );
}

while ( my $rev = shift @revisions ) {
	my $file = $list_files{ $rev };
	my $path = "$files_dir/$file";
	my @s = stat $path;
	my @t = gmtime $s[ 9 ];
	my $t = sprintf "%04d-%02d-%02d", $t[ 5 ] + 1900, $t[ 4 ] + 1, $t[ 3 ];
	my $md5 = `md5sum $path`;
	$md5 =~ s/\s+.*//s;

	my $head = <<"EOF";
index:	-$rev
title:	r$rev
desc:	
	<ul>
		<li>File: <a href="$html_files_dir/$file">$file</a></li>
		<li>Date: $t</li>
		<li>Size: $s[7]</li>
		<li>MD5: <tt>$md5</tt></li>
	</ul>

body:	
	<h2>SVN changelog</h2>
EOF

	page_changelog( "r$rev", $head, $rev, $revisions[ 0 ] );
}
