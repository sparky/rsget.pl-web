#!/usr/bin/perl
#
# 2010 (c) Przemysław Iskra <sparky@pld-linux.org>
#       This program is free software,
# you may distribute it under GPL v2 or newer.
#
use strict;
use warnings;

package config;
my $defaults = {
	remote => "http://localhost:7666/",
	ignore_ssl_cert => 0, # 0 | 1
	fork => 0, # 0 | 1
	popup => 1, # 0 | 1
	disable_after => 16, # 1+
	interval => 5, # 2+
	window_hint => 'normal', # normal | dialog | menu | toolbar | splashscreen
		# | utility | dock | desktop | dropdown-menu | popup-menu | tooltip
		# | notification | combo | dnd
	window_type => 'toplevel', # toplevel | popup
	opacity => 1, # 0.0 < opacity <= 1.0
};

{
package config; # {{{
use Carp;
our $AUTOLOAD;

my $allowed = {
	remote => qr{https?://\S+/(.*/)?}o,
	ignore_ssl_cert => qr{0|1}o,
	fork => qr{0|1}o,
	popup => qr{0|1}o,
	interval => qr{0*[1-9][0-9]*}o,
	disable_after => qr{0*[1-9][0-9]*}o,
	window_hint => qr{normal|dialog|menu|toolbar|splashscreen|utility|dock
		|desktop|dropdown-menu|popup-menu|tooltip|notification|combo|dnd}xo,
	window_type => qr{toplevel|popup}o,
	opacity => qr{1(?:\.0+)?|0\.[0-9]+}o,
};

sub AUTOLOAD() : lvalue
{
	my $class = shift;
	( my $name = $AUTOLOAD ) =~ s/.*:://;
	$name =~ tr/-/_/;
	unless ( exists $allowed->{ $name } ) {
		croak "Can't find config variable `$name'\n";
	}

	$defaults->{ $name };
}

sub init
{
	my $class = shift;
	my $argre = qr/[a-z_-]+/o;
	while ( $_ = shift ) {
		if ( /^--($argre)=(.*)$/o ) {
			config->$1 = $2;
		} elsif ( /^--no-($argre)$/o ) {
			config->$1 = 0;
		} elsif ( /^--($argre)$/o ) {
			config->$1 = 1;
		} else {
			croak "'$_' is not a valid argument\n";
		}
	}

	my $bad = 0;
	foreach my $key ( sort keys %$allowed ) {
		unless ( config->$key =~ /^$allowed->{$key}$/ ) {
			warn 'config: value `' . config->$key . "' is not valid for `$key'\n";
			$bad++;
		}
	}

	croak "config: there are errors\n" if $bad;
}

# package config; }}}
}

{
package WWW; # {{{
use WWW::Curl::Easy;
use WWW::Curl::Multi;

my $multi;
my %active;

sub init
{
	$multi = new WWW::Curl::Multi;
}

sub get
{
	my $class = shift;
	my $file = shift;
	my $uri = config->remote . $file;
	my $call = shift;
	my $objid = shift;

	my $id = 1;
	++$id while exists $active{ $id };

	my $curl = new WWW::Curl::Easy;
	my $self = {
		curl => $curl,
		id => $id,
		call => $call,
		file => $file,
		objid => $objid,
		body => "",
	};

	$curl->setopt( CURLOPT_PRIVATE, $id );
	$curl->setopt( CURLOPT_URL, $uri );
	$curl->setopt( CURLOPT_FOLLOWLOCATION, 1 );
	$curl->setopt( CURLOPT_ENCODING, 'gzip,deflate' );
	$curl->setopt( CURLOPT_CONNECTTIMEOUT, config->interval - 1 );
	$curl->setopt( CURLOPT_WRITEFUNCTION, \&_write_scalar );
	$curl->setopt( CURLOPT_WRITEDATA, \$self->{body} );
	if ( config->ignore_ssl_cert ) {
		$curl->setopt( CURLOPT_SSL_VERIFYPEER, 0 );
		$curl->setopt( CURLOPT_SSL_VERIFYHOST, 0 );
	}

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

sub tick
{
	my $class = shift;
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

	Tray->notify( curl => $err ?
		"error($err): " . $data->{curl}->errbuf :
		undef );
	my $response;
	if ( ( my $code = $data->{curl}->getinfo( CURLINFO_RESPONSE_CODE ) ) != 200 ) {
		$data->{body} =~ m#<title>(.*)</title>#;
		$response = "$code: $1";
	}
	Tray->notify( "curl response" => $response );

	delete $data->{curl};

	my $call = $data->{call};
	&$call( $data->{objid}, $err ? undef : $data->{body} );
}

# package WWW; }}}
}

{
package Pixbuf; # {{{
use Carp;
our $AUTOLOAD;

my %pixbuf_cache;
my %pixbuf_source = (
	hook =>
		'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAphJREF
		UOMt9k01olFcUhp977/cT7+hEHCeRJpla0IWgdJG6EKoRSRcVCt20i4IgSOsqCyF00YW6E0J
		2rrQtFFz5syiFulB3GTdudGcQamEUhzokmUnmc76Z+917uoiRIahn+Z73PJzD4VVsq8XFxWv
		AceDQkPwUWJqfnz+/3a94T30ZxyWgqZTataWJyGVgoe5cb9hr3gdohOA+jePPlNbTWmuU1ii
		lTqLUuZrWTxoh/PtRAMDBUulxnCSn4jTdFyUJ2hgU7AR+mFKq3QjhEYD6ZnLyOx1FZ4rB4ML
		fr179Mwz5tlaz8Y4dd7QxXw/ynDzL6Pd6FIMBwfsTdeeWzOHx8Wp5z54rcZL8eLBUkuV2e2k
		LsNzpuGMHDtwqj419lVo7KSIE7/FFASKfT2n9mwL4aWbmpYhM5FlGnmXf315evj28ydzp02O
		jlcp/rxsNWi9esLG2hstzfFF8oQFCCH/GSUJqLaPV6sLc7Gw0DLh69+7rXZVKf+fu3aTWYqI
		IpRRATQP0s+z3oijQWjNi7f7I2svDgItnz86MWBvpKEJvfgTZbNXU27+r/UeOdI0x1pbLVCY
		mOoVzZwQepmn6SbVWu99bX9/38tkzms+f02m16L95gy+KnyOAunNSWV19GifJtAC2XB6tTk3
		9Vd67F6UUWbvNSrPJxurq1iAiAvDg3a1Zp/NrnKbTwXuMMQTvWV9ZAaC3sUG71aLTapFnGYV
		zSAhN4Mk7QN7tXvfOnQveHw3ek2cZycgIIkK/1yPvdsmzjEGeE7xHRC7VnRO1LQMTURz/Eaf
		prIljjDGICN57isGAwrnN4RB+qTt35YNhOmnteWBBaV0WERAhhOAkhHsicqPu3M2PpvHtNho
		YB2pAFXhYd25tu+9/xSE1DK9WNhIAAAAASUVORK5CYII=',
	hook_gray =>
		'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAQAAAC1+jfqAAAAAXNSR0IArs4c6QAAAYBJREF
		UKM9tkU9IFGEYh59vdlqd6Y9837huuw5rVASal1KP0qEOXSoQtFPX9tQp8OBFb0EQdC0RvAc
		REV06hlBQJAR16RBYLYlt7qpjujv+OgyrBj3v7eE5vPAzIuPBI8YZBOAzr+9W6aD9s0dt08n
		Jyc7aoGMPBcI9jtSrXkVyNXv5P0Epjj8MaECxiopa9o4QnJscen72TCcZDC+8HNWwTqukSHZ
		ceMFqdM19HJ7JPvqU9NwovyljCfHxHjrPiKvf1J+QTL1/kkUTfdHPFb6zzh/SUQ/2nuUJiO5
		f97Pg6ard6SHAx0DFg2ShjUd4qnsuC6qXQt/HwwBUjHBmaDMXHqfUaN/SUlc5frV58gtfWSM
		hnTYCzr/Lj5ygTIzD0OAHK9RossPeRR+gOZ8fScmRUgc2+MUaCS1UY9kIcCb/NhgLOUY3Yps
		tErZpo9v1eZON5fr9xa4rR8ghUnZpkaKZ+r1/xipUC42i+lRQtOte2JuZNeIA51GkQoGl+u+
		O+wugYKeIzr1tUgAAAABJRU5ErkJggg==',
	hook_red =>
		'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAplJREF
		UOMt9k09oVFcUxn/3z5uXN/PiM4Y2UvHhQhCXYly4aAvWhRWKK7souJAoosiIGxdBaHaFrDT
		YlLYpFrqp1EXpRrDZiVCKYFFENxHE/4lDZsaZufPmvXdPF6YyBO23PPfjd+7hnE+xTpfn578
		HPgZ2DpXvAzeOnjp1Yr1f8Q7NRVENeK6VGv2v5kVmgNm6c27Yq98FqDvX1cb8qqxFVSqoSgU
		TBDPamIdzUfTZsNfwHh0aH79tarV9No43m2oVXakAxErkqwNaN68Vxd8AamHXrsOE4RF6vbP
		H7txZGoYsTE5WJUmuYu3nqtNBGg3KVouy26XM80/qzt3QJMlymaZf+DS9u7B37/Qw4NitW71
		iYuJQtn37X4MdOyBNsWNj6DDEGHNhLoq0Avh2auqJEtli2m10s/nl8cXF34ZBl86c+VDH8Ut
		58YLwwQP848fk7TZllk1qAOX97xKGlKOj5Fu3zl46edIOA05fvLg8EkWZTxIkSVBhiNIaINU
		Apt3+iaJAtMbXatskimaGAd+dP/+pDQKrjEGMAa2RN0+pWtu7Gjl4sOOtrZZjY6jx8ZZ4f0T
		gpjHmo9GNG/8c9PubeysrhPfuIUtL5KurlFl2zq7tXRaePr2vo2i3AgZxnFST5I+ROEYpRdb
		t0ut0sK9eoZpNfJaB9wCLb2f1z579qOJ4t8lzAmvpeU9/7eh8v0+wvIx99AjfaFD0+0hRPAf
		+eQvor6z8EDg3ZfN8jy0KdKuFr9VQIujXr1GNBtJoULTbyGCAF/m67pyodRnYYqPoZxvH+1U
		UoYIAvEfyHN/tvuk8GODLcrru3DfvDdP8pk0ngFllzAbxHkSQosilKK57kV/qzl353zSu/UY
		DE0AKfADcrDu3ut73L7YmIVdlCGXKAAAAAElFTkSuQmCC',
);

sub new
{
	my $data = shift;
	my $ret;
	eval {
		my $loader = new Gtk2::Gdk::PixbufLoader;
		$loader->write( $data );
		$loader->close();
		$ret = $loader->get_pixbuf();
	};
	if ( $@ ) {
		warn "Cannot load pixbuf from data: $@\n";
		return undef;
	}

	return $ret;
}

sub AUTOLOAD
{
	my $class = shift;
	( my $name = $AUTOLOAD ) =~ s/.*:://;
	unless ( exists $pixbuf_source{ $name } ) {
		croak "Can't find image `$name'\n";
	}

	return $pixbuf_cache{ $name } ||= new(
		MIME::Base64::decode( $pixbuf_source{ $name } )
	);
}

# package Pixbuf; }}}
}

{
package Tray; # {{{
use Glib qw(TRUE FALSE);
use Gtk2 ();
use MIME::Base64 ();


my $self;
sub init
{
	$self = {
		active => FALSE,
		notify => {},
	};
	my $icon = $self->{icon} = new_from_pixbuf Gtk2::StatusIcon Pixbuf->hook_gray;

	my $menu = $self->{menu} = Gtk2::Menu->new();
	{
		my $m_web = Gtk2::ImageMenuItem->new_from_stock( 'gtk-open' );
		$m_web->signal_connect( 'activate', \&_sig_web );
		$menu->append( $m_web );
	}

	{
		my $m_popup = new Gtk2::CheckMenuItem 'Auto _Popup';
		$m_popup->set_active( config->popup );
		$m_popup->signal_connect( 'activate', \&_sig_toggle_popup );
		$menu->append( $m_popup );
	}

	$menu->append( new Gtk2::SeparatorMenuItem );

	{
		my $m_quit = Gtk2::ImageMenuItem->new_from_stock( 'gtk-quit' );
		$m_quit->signal_connect( 'activate', \&_sig_quit );
		$menu->append( $m_quit );
	}

	$icon->signal_connect( 'activate', \&SlideShow::toggle );
	$icon->signal_connect( 'popup-menu', \&_sig_menu );

	Tray->notify( unused => 1 );
	Tray->notify( unused => undef );
}

sub notify
{
	my ( $class, $key, $value ) = @_;
	my $notify = $self->{notify};
	if ( defined $value ) {
		return if exists $notify->{$key} eq $value;
		$notify->{$key} = $value;
	} else {
		return unless exists $notify->{$key};
		delete $notify->{$key};
	}
	my @args = "rsget.pl captcha asker";
	push @args, map "$_: $notify->{$_}", sort keys %$notify;
	$self->{icon}->set_tooltip( join "\n\t", @args );
	$0 = join "; ", @args;
}

sub position_menu
{
	my ($x, $y, $push_in ) = Gtk2::StatusIcon::position_menu( $self->{menu}, $self->{icon} );
	return ( $x, $y, 0 );
}

sub _sig_web
{
	Gtk2::show_uri( undef, config->remote );
}

sub _sig_toggle_popup
{
	config->popup = (shift)->get_active() ? 1 : 0;
}

sub _sig_quit
{
	Gtk2->main_quit();
}

sub _sig_menu
{
	my ( $widget, $button, $time ) = @_;

	my $menu = $self->{menu};
	$menu->show_all();
	$menu->popup( undef, undef, \&position_menu, undef, 0, $time );
}

sub active
{
	my $class = shift;
	my $isactive = ( shift ) ? TRUE : FALSE;
	return if $self->{active} == $isactive;
	$self->{active} = $isactive;
	$self->{icon}->set_from_pixbuf( $isactive ? Pixbuf->hook_red : Pixbuf->hook_gray );
	$self->{icon}->set_blinking( $isactive ? TRUE : FALSE );
}

# package Tray; }}}
}

{
package Window; # {{{
use Glib qw(TRUE FALSE);

my $self;
sub init
{
	my $window = new Gtk2::Window config->window_type;
	$window->set_type_hint( config->window_hint );
	$window->set_accept_focus( TRUE );
	$window->set_keep_above( TRUE );

	$window->set_default_icon( Pixbuf->hook );
	$window->set_default_size( 200, 50 );
	$window->set_opacity( config->opacity ) if config->opacity != 1;
	$window->signal_connect( delete_event => sub { SlideShow::disable(); return TRUE; } );

	$window->set_wmclass( "rsget.pl", "rsget.pl-gtk-captcha" );
	$window->set_title( "rsget.pl captcha asker" );


	my $vbox = new Gtk2::VBox FALSE, 5;
	$window->add( $vbox );

	my $pbar = new Gtk2::ProgressBar;
	$pbar->set_orientation( 'right-to-left' );
	$pbar->set_fraction( 0.0 );
	$vbox->add( $pbar );

	my $img = new_from_pixbuf Gtk2::Image Pixbuf->hook;
	$vbox->add( $img );

	my $entry = new Gtk2::Entry;
	$entry->signal_connect( activate => \&_set_captcha );
	$vbox->add( $entry );

	$self = {
		window => $window,
		pbar => $pbar,
		img => $img,
		entry => $entry,
	};
}

sub set
{
	my $class = shift;
	my $show = shift;

	my $window = $self->{window};
	if ( $show ) {
		$self->{max_pbar} = int ( 1 + $show->{end} - time);
		$self->{img}->set_from_pixbuf( $show->{img} );
		$self->{entry}->set_text( "" );

		if ( not $self->{active} ) {
			unless ( defined $self->{x} ) {
				( $self->{x}, $self->{y}, my $unused ) = Tray->position_menu;
			}
			$window->stick();
			$window->show_all;
			$window->move( $self->{x}, $self->{y} );
		}
		$self->{active} = $show;
		$window->set_focus( $self->{entry} );
	} else {
		$self->{active} = undef;
		($self->{x}, $self->{y}) = $window->get_position();
		$window->set_default_size( 200, 50 );
		$window->hide_all();
	}
}

sub active
{
	return $self->{active};
}

sub tick
{
	my $class = shift;
	my $time = shift;
	my $image = $self->{active}
		or return;
	my $pbar = $self->{pbar};

	my $left = $image->update( $time ) || 0;
	$pbar->set_fraction( $left / $self->{max_pbar} );
	$left = int $left;
	$pbar->set_text( sprintf "%d:%.2d", int ($left / 60), $left % 60 );

	return $left;
}

sub _set_captcha
{
	my $entry = shift;
	my $md5 = shift;
	my $val = $entry->get_text;

	return unless $val;
	$self->{active}->set_captcha( $val );
}

# package Window; }}}
}

{
package Image; # {{{

sub new
{
	my $class = shift;
	my $md5 = shift;
	my $timeout = shift;

	my $self = {
		md5 => $md5,
	};

	bless $self, $class;

	$self->timeout( $timeout );
	$self->_get_image();

	return $self;
}

sub _get_image
{
	my $self = shift;
	WWW->get( "captcha?md5=$self->{md5}", \&_add_image, $self->{md5} );
}

sub _add_image
{
	my $self = SlideShow->get( shift );
	my $data = shift;
	unless ( $self ) {
		warn "_add_image without object\n";
		return;
	}

	return $self->_get_image() unless defined $data;

	if ( $self->{img} = Pixbuf::new( $data ) ) {
		SlideShow->maybe_enable;
	} else {
		# captcha error, request new one
		$self->set_captcha( "" );
	}
}

sub timeout
{
	my $self = shift;
	my $timeout = shift;

	require Time::HiRes;
	my $end = $timeout + Time::HiRes::time();
	$self->{end} = $end if not $self->{end} or $self->{end} > $end;
}

sub set_captcha
{
	my $self = shift;
	my $val = shift;
	$self->{sent} = $val;

	WWW->get( "captcha?md5=$self->{md5}&solve=$val", \&_ret_captcha, $self->{md5} );
	SlideShow->next();
}

sub _ret_captcha
{
	my $md5 = shift;
	my $data = shift;

	warn "Captcha returned: $data\n" unless config->fork;
}

sub update
{
	my $self = shift;
	my $time = shift;

	return undef if $time >= $self->{end};
	return $self->{end} - $time;
}

# package Image; }}}
}

{
package SlideShow; # {{{
my %all;
my $last_at = 0;

sub get
{
	my $class = shift;
	my $md5 = shift;
	return $all{ $md5 };
}

sub next
{
	my $class = shift;
	my $first;
	$last_at = time;
	my $maxend = 1000 + $last_at;

	foreach ( values %all ) {
		if ( $_->{img} and not $_->{sent}
				and $_->{end} < ( $first->{end} || $maxend ) ) {
			$first = $_;
		}
	}

	Window->set( $first );
}

sub maybe_enable
{
	return if Window->active;
	if ( config->popup or $last_at + config->disable_after > time ) {
		SlideShow->next();
	}
}

sub disable
{
	$last_at = 0;
	Window->set( undef );
}

sub toggle
{
	if ( Window->active ) {
		disable();
	} else {
		SlideShow->next();
	}
}

$SIG{USR1} = \&toggle;

sub from_list
{
	my $unused = shift;
	my $data = shift;

	return unless defined $data;

	my @md5s = keys %all;
	my %left;
	@left{ @md5s } = (1) x scalar @md5s;

	foreach ( split /\n+/, $data ) {
		next unless /([0-9a-f]{32})\s+(\d+)/;
		my $md5 = $1;
		my $timeout = $2;
		delete $left{ $md5 };
		if ( $all{ $md5 } ) {
			$all{ $md5 }->timeout( $timeout );
		} else {
			$all{ $md5 } = new Image $md5, $timeout;
		}
	}

	foreach ( keys %left ) {
		delete $all{ $_ };
	}
	if ( my $act = Window->active ) {
		SlideShow->next() if exists $left{ $act->{md5} };
	}
}

sub tick
{
	my $class = shift;
	my $time = shift;

	my $all = 0;

	foreach ( values %all ) {
		if ( not defined $_->{sent} ) {
			if ( $_->update( $time ) ) {
				$all++;
			} else {
				$_->{sent} = "UNSOLVED";
			}
		}
	}

	Tray->notify( "to solve" => $all || undef );
	Tray->active( $all );
}

# package SlideShow; }}}
}

package main;
use Time::HiRes ();
use Glib qw(TRUE FALSE);
use Gtk2;

Gtk2->init();
config->init( @ARGV );
if ( config->fork ) {
	my $pid = fork();
	if ( $pid ) {
		print "Started on pid: $pid\n";
		exit 0;
	}
}
WWW->init();
Tray->init();
Window->init();

my $time_list = 0;
my $time_last = 0;
sub tick
{
	WWW->tick();

	my $time = Time::HiRes::time();
	if ( my $image = Window->active ) {
		unless ( Window->tick( $time ) ) {
			$image->{sent} = "UNSOLVED";
			SlideShow->next();
		}
	}

	SlideShow->tick( $time );

	if ( $time_list + config->interval < $time ) {
		WWW->get( "captcha", \&SlideShow::from_list );
		$time_list = $time;
	}


	return TRUE;
}

Glib::Timeout->add( 200, \&tick );
Gtk2->main;

# vim: ts=4:sw=4:fdm=marker
