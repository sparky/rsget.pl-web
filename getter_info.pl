#!/usr/bin/perl
#
use strict;
use warnings;

my $src = "svn";
my $out = "src/getters";

my %getters = ();

foreach my $dir ( qw(Get Video Audio Image Link) ) {
	foreach my $f ( glob "$src/$dir/*" ) {
		next if $f =~ /~$/;
		$getters{ $f } = 1;
		getter_info( $f );
	}
}
foreach my $dir ( qw(Get Video Audio Image Link) ) {
	foreach my $f ( glob "$out/$dir/*" ) {
		next unless -d $f;
		$f =~ s/^$out/$src/;
		die "getter $f does not exist"
			unless $getters{ $f };
	}
}

sub getter_info
{
	my $file = shift;
	my %tags;

	my $pre = "";
	open F_IN, "<", $file;
	while ( <F_IN> ) {
		$pre .= $_;
		if ( /^([a-z]+):\s*(.*)$/ ) {
			$tags{ $1 } = $2 unless exists $tags{ $1 };
		}
	}
	close F_IN;
	my @stat = stat $file;

	my $outfile = $file;
	$outfile =~ s#^$src#$out#;

	print "Writing $outfile...";
	mkdir "$outfile";
	$outfile .= "/index.xml";

	my $tos = "";
	$tos = "<p>Check <a href=$tags{tos}>terms of service</a>.</p>\n"
		if $tags{tos};

	$pre =~ s/&/&amp;/g;
	$pre =~ s/</&lt;/g;
	$pre =~ s/>/&gt;/g;

	open F_OUT, ">", $outfile;
	print F_OUT <<EOF;
index:	0
title:	$tags{name}
desc:	[$tags{short}] <a href=$tags{web}>$tags{web}</a>

body:	
	$tos<p>Status: $tags{status}</p>
	<pre>$pre</pre>
EOF

	close F_OUT and print " OK\n" or print " FAILED!\n";
	utime $stat[ 8 ], $stat[ 9 ], $outfile;
}
