#!/usr/bin/perl
#
use strict;
use warnings;
use File::Find ();
use File::Path ();
use File::Copy ();
use Data::Dumper;
use DateTime::Format::W3CDTF;
my $w3c = DateTime::Format::W3CDTF->new;

my $uri = "http://rsget.pl/";
my $src = "src/";
my $templatesdir = "templates";
my $dest = "rsget.pl";

my %dirs;

my $processed;
my %templates;

sub read_template
{
	my $name = shift;
	my $file = "$templatesdir/template.$name.xml";
	open my $f_in, "<", $file or die "Cannot open $file: $!\n";
	local $/ = undef;
	return <$f_in>;
}

foreach my $name ( qw(column index ajax) ) {
	$templates{ $name } = read_template( $name );
}

my %special = (
	"index.xml" => \&generate,
	"index.php" => \&generate,
);

sub skip
{
	my $dir = shift;
	my $name = shift;
	my $file = $dir.$name;
	print "Skipping: $file\n";
}

sub generate
{
	my $dir = shift;
	my $name = shift;
	my $file = $src.$dir.$name;
	print "Processing: $file\n";

	my @stat = stat $file;
	my %tags = (
		_dir => $dir,
		_name => $name,
		_atime => $stat[ 8 ],
		_mtime => $stat[ 9 ],
	);
	my $tag;
	open my $f_in, "<", $file or die "Cannot open $file: $!\n";
	while ( <$f_in> ) {
		if ( s/^([a-z]+):(?:\t|$)// ) {
			$tag = "_" . $1;
			$tags{ $tag } = "";
			if ( $tag eq "_body" ) {
				$tags{ $tag } = join "", <$f_in>;
				last;
			}
		}
		if ( $tag ) {
			$tags{ $tag } .= $_;
		}
	}
	foreach ( values %tags ) {
		s/^\s+//s;
		s/\s+$//s;
	}

	my $dest = $processed ||= {};
	foreach ( split m#/+#, $dir ) {
		$dest = $dest->{$_} ||= {};
	}

	@{$dest}{ (keys %tags) } = (values %tags);
}

sub copy
{
	my $dir = shift;
	my $name = shift;
	my $file = $dir.$name;
	print "Copying: $src$file -> $dest/$file\n";
	link $src.$file, "$dest/$file"
		or File::Copy::copy( $src.$file, "$dest/$file" );
}

sub wanted
{
	return if -d;
	return if /~$/;
	return if /\.bak$/;
	return if m{/\.+$};
	return if m{/\..+\.swp};
	#return if m#/\.#;

	s#^$src##;
	my $dir = "";
	$dir = $1 if s#^(.*/)##;
	my $file = $_;
	File::Path::mkpath( "$dest/$dir" );

	my $func = $special{ $file } || \&copy;

	&$func( $dir, $file );
}

File::Find::find( { wanted => \&wanted, no_chdir => 1 }, $src );

#print Dumper( $processed );
#exit;

sub subpages
{
	my $branch = shift;
	return sort { $branch->{$a}->{_index} <=> $branch->{$b}->{_index}
		or $a cmp $b } grep { ref $branch->{$_} } keys %$branch;
}

sub recursive
{
	my $branch = shift;
	my @columns = @_;

	push @columns, make_column( $branch, @columns );
	write_templates( @columns );

	foreach ( subpages $branch ) {
		next if /^_/;
		recursive( $branch->{$_}, @columns );
	}
}

recursive( $processed, () );


sub process_template
{
	my $name = shift;
	my $c = shift;

	local $_ = $templates{ $name };
	s#<content:([a-z_]+)\s*/>#defined $c->{$1} ? $c->{$1} : "<ERROR: $1>"#esg;
	return $_;
}

sub make_sublist
{
	my $branch = shift;
	my @columns = @_;

	my $list = "";
	foreach my $name ( subpages $branch ) {
		my $subbranch = $branch->{ $name };
		$list .= "<dt><a href=\"/$subbranch->{_dir}\">$subbranch->{_title}</a></dt>\n";
		$list .= "<dd>$subbranch->{_desc}";
		my $sublist = "";
		foreach my $subname ( subpages $subbranch ) {
			my $subsubbranch = $subbranch->{ $subname };
			$sublist .= "<a href=\"/$subsubbranch->{_dir}\">$subsubbranch->{_title}</a>,\n";
		}
		$sublist =~ s/,\n$//s;
		$list .= "<br />\n($sublist)" if length $sublist;

		$list .= "</dd>\n";
	}
	$list = "<div class=\"sublist\"><h2>Subpage list</h2>\n<dl>$list</dl></div>\n" if length $list;
	return $list;
}

sub h_id
{
	my $h = shift;
	my $num = shift;
	my $title = shift;
	local $_ = lc $title;
	s#[^0-9a-z]+#_#g;
	$_ = "c" . $num . "_" . $_;
	return qq(<$h id="$_"><a href="#$_">$title</a></$h>);
}

sub make_column
{
	my $branch = shift;
	my @columns = @_;

	my @dirs = split m#/+#, $branch->{_dir};
	my $num = scalar @dirs;
	my $body = $branch->{_body};
	$body =~ s#<(h[1-6])>(.*?)</\1>#h_id( $1, $num, $2 )#eg;
	my %cont = (
		title => $branch->{_title},
		logo => $branch->{_logo} || "",
		description => $branch->{_desc},
		body => $body,
		column_id => $num,
		class => "",
	);
	if ( $branch->{_name} eq "index.php" ) {
		$cont{class} = " nocache";
	}

	$cont{sublist} = make_sublist( $branch, @columns );

	$branch->{_processed} = process_template( "column", \%cont );

	return $branch;
}

sub write_templates
{
	my @columns = @_;
	my $branch = pop @_;

	my $titles = join ": ", map { $_->{_title} } @columns;
	my $columns = join "\n", map { $_->{_processed} } @columns;
	my %cont = (
		titles => $titles,
		columns => $columns,
		column => $branch->{_processed},
		head => "",
	);
	my $ext = $branch->{_name};
	$ext =~ s/^index//;
	if ( $ext eq ".php" ) {
		$cont{head} = qq{<?php
header('Content-type: text/xml');
echo '<?xml version="1.0" encoding="utf-8"?>';
?>};
	} else {
		$cont{head} = qq{<?xml version="1.0" encoding="utf-8"?>};
	}

	my $ajax = process_template( "ajax", \%cont );
	my $index = process_template( "index", \%cont );

	my $file =  "$dest/$branch->{_dir}index$ext";
	open F_OUT, ">", $file or die "Can't create $file: $!";
	print F_OUT $index;
	close F_OUT and print "Wrote $file\n";
	#utime $branch->{_atime}, $branch->{_mtime}, $file;

	my $dir = "$dest/$branch->{_dir}_ajax";
	mkdir $dir;

	$file =  "$dir/index$ext";
	open F_OUT, ">", $file or die "Can't create $file: $!";
	print F_OUT $ajax;
	close F_OUT and print "Wrote $file\n";
	utime $branch->{_atime}, $branch->{_mtime}, $file;

	$dirs{ $branch->{_dir} } = $branch;
}

sub sitemap
{
	my $file =  "$dest/sitemap.xml";
	open F_OUT, ">", $file or die "Can't create $file: $!";
	print F_OUT <<'EOF';
<?xml version='1.0' encoding='UTF-8'?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
	http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
EOF
	foreach ( sort { ( ( scalar split m#/+#, $a ) <=> ( scalar split m#/+#, $b ) )
			or $a cmp $b } keys %dirs ) {
		my $pri = sprintf "%.1f", 1.0 - (scalar split m#/+#, $_) / 5;
		my $d = DateTime->from_epoch( epoch => $dirs{ $_ }->{_mtime} );
		my $t = $w3c->format_datetime( $d ); 
		
		print F_OUT <<"EOF";
    	<url>
		<loc>$uri$_</loc>
		<priority>$pri</priority>
		<lastmod>$t</lastmod>
	</url>
EOF
	}
	print F_OUT <<'EOF';
</urlset>
EOF
	close F_OUT and print "Wrote $file\n";
}

sitemap();
