#!/usr/bin/perl

use strict;
use warnings;

our $remote = $ARGV[0] || "http://localhost:7666/";

package WWW;
use WWW::Curl::Easy;
use WWW::Curl::Multi;

my $multi = new WWW::Curl::Multi;
my %active;

sub get
{
	my $file = shift;
	my $uri = $main::remote . $file;
	my $call = shift;

	my $id = 1;
	++$id while exists $active{ $id };

	my $curl = new WWW::Curl::Easy;
	my $self = {
		curl => $curl,
		id => $id,
		call => $call,
		file => $file,
		body => "",
	};

	$curl->setopt( CURLOPT_PRIVATE, $id );
	$curl->setopt( CURLOPT_URL, $uri );
	$curl->setopt( CURLOPT_FOLLOWLOCATION, 1 );
	$curl->setopt( CURLOPT_ENCODING, 'gzip,deflate' );
	$curl->setopt( CURLOPT_CONNECTTIMEOUT, 20 );
	$curl->setopt( CURLOPT_WRITEFUNCTION, \&_write_scalar );
	$curl->setopt( CURLOPT_WRITEDATA, \$self->{body} );

	$active{ $id } = $self;
	$multi->add_handle( $curl );

	return 1;
}

sub _write_scalar
{
	my ($chunk, $scalar) = @_;
	$$scalar .= $chunk;
	return length $chunk;
}

sub perform
{
	my $running = scalar keys %active;
	return unless $running;
	my $act = $multi->perform();
	return if $act == $running;

	while ( my ($id, $rv) = $multi->info_read() ) {
		_finish( $id, $rv ) if $id;
	}
}

sub _finish
{
	my $id = shift;
	my $err = shift;

	my $data = $active{ $id };
	delete $active{ $id };

	delete $data->{curl};

	my $call = $data->{call};
	&$call( $data->{file}, $err ? undef : $data->{body} );
}

package GUI;
use Glib qw(TRUE FALSE);
use Gtk2 qw(-init);

my $window;
my $vbox;

{
	$window = new Gtk2::Window 'toplevel';
	$window->set_default_size( 240, 50 );
	$window->signal_connect( destroy => sub { Gtk2->main_quit; $window = $vbox = undef; } );
	$window->set_border_width( 5 );

	$window->set_title( "rsget.pl captcha asker" );
	$vbox = new Gtk2::VBox FALSE, 5;
	$window->add( $vbox );
	$window->show_all;
}

sub new
{
	my $class = shift;
	my $md5 = shift;


	my $frame = new Gtk2::Frame $md5;
	$vbox->pack_start( $frame, FALSE, FALSE, 0 );
	my $box = new Gtk2::VBox FALSE, 5;
	$frame->add( $box );

	my $pbar = new Gtk2::ProgressBar;
	$pbar->set_orientation( 'right-to-left' );
	$pbar->set_fraction( 0.0 );

	$box->add( $pbar );
	$window->show_all;

	my $self = {
		md5 => $md5,
		time_end => 200 + time,
		frame => $frame,
		box => $box,
		pbar => $pbar,
	};

	return bless $self, $class;
}

sub DESTROY
{
	my $self = shift;
	delete $active{ $self->{md5} };

	$vbox->remove( $self->{frame} ) if $self->{frame} and $vbox;
	$window->resize( 240, 50 );
	$window->show_all if $window;
}

sub timeout
{
	my $self = shift;
	my $time = shift;

	my $end = $time + time;
	$self->{time_end} = $end if $self->{time_end} > $end;
}

sub update
{
	my $self = shift;
	my $pbar = $self->{pbar};

	my $left = $self->{time_end} - time;
	$left = 0 if $left < 0;
	$pbar->set_fraction( $left / 200 );
	$pbar->set_text( sprintf "%d:%.2d", int ($left / 60), $left % 60 );

	return $left;
}

sub image
{
	my $self = shift;
	my $data = shift;

	my $pixbufloader = new Gtk2::Gdk::PixbufLoader;
	eval {
		$pixbufloader->write( $data );
		$pixbufloader->close();
	};
	return if $@;
	my $pixbuf = $pixbufloader->get_pixbuf();
	my $img = new_from_pixbuf Gtk2::Image $pixbuf;
	$self->{box}->add( $img );

	my $entry = $self->{entry} = new Gtk2::Entry;
	$self->{box}->add( $entry );

	$entry->signal_connect( activate => \&_set_captcha, $self->{md5} );
	$entry->signal_emit( "focus", undef );

	$window->show_all;
}

sub _set_captcha
{
	my $entry = shift;
	my $md5 = shift;
	my $val = $entry->get_text;

	return unless $val;

	WWW::get( "captcha?md5=$md5&solve=$val", sub { } );
	$entry->set_editable( FALSE );
}


package main;
use Glib qw(TRUE FALSE);
use Gtk2;

my %image;

sub process_list
{
	my $uri = shift;
	my $data = shift;

	return unless defined $data;

	my @md5s = keys %image;
	my %left;
	@left{ @md5s } = (1) x scalar @md5s;

	foreach ( split /\n+/, $data ) {
		next unless /([0-9a-f]{32})\s+(\d+)/;
		my $md5 = $1;
		my $timeout = $2;
		delete $left{ $md5 };
		unless ( $image{ $md5 } ) {
			$image{ $md5 } = new GUI $md5;
			WWW::get( "captcha?md5=$md5", \&process_image );
		}
		$image{ $md5 }->timeout( $timeout );
	}

	foreach ( keys %left ) {
		delete $image{ $_ };
	}
}

sub process_image
{
	my $uri = shift;
	my $data = shift;

	unless ( defined $data ) {
		WWW::get( $uri, \&process_image );
		return;
	}

	$uri =~ m/md5=([0-9a-f]{32})/;
	my $md5 = $1;

	$image{ $md5 }->image( $data );
}

my $time_list = 0;
sub tick
{
	WWW::perform();

	foreach my $md5 ( keys %image ) {
		unless ( $image{ $md5 }->update() ) {
			delete $image{ $md5 };
			$time_list = 0;
		}
	}

	my $t = time;
	if ( $time_list + 5 < $t ) {
		WWW::get( "captcha", \&process_list );
		$time_list = $t;
	}

	return TRUE;
}

Glib::Timeout->add( 250, \&tick );
Gtk2->main;