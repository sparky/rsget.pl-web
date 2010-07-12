<?php /* {{{ */
if ( ! isset( $_SERVER["PATH_TRANSLATED"] ) || ! ereg( ".user.js$", $_SERVER["PATH_TRANSLATED"] ) ) {
	header( 'Refresh: 1;url=/tools/userscript/config.php/rsgetpl.user.js' );
}
header( 'Content-type: text/javascript' );
$exp = time() + 60 * 60 * 24 * 150;
$cpath = "/tools/userscript/";
$host = "http://localhost:7666/";
$open = 0;
$uzbl = 0;
if ( isset( $_POST["host"] ) && $_POST["host"] ) {
	$host = $_POST["host"];
	$open = $_POST["open_supported"] ? 1 : 0;
	$uzbl = $_POST["uzbl_hacks"] ? 1 : 0;
} else if ( isset( $_GET["host"] ) && $_GET["host"] ) {
	$host = $_GET["host"];
	$open = $_GET["open_supported"] ? 1 : 0;
	$uzbl = $_GET["uzbl_hacks"] ? 1 : 0;
} else if ( isset( $_REQUEST["host"] ) && $_REQUEST["host"] ) {
	$host = $_REQUEST["host"];
	$open = $_REQUEST["open_supported"] ? 1 : 0;
	$uzbl = $_REQUEST["uzbl_hacks"] ? 1 : 0;
}
setcookie( "host", $host, $exp, $cpath );
setcookie( "open_supported", $open, $exp, $cpath );
setcookie( "uzbl_hacks", $uzbl, $exp, $cpath );
/* }}} */ ?>
// ==UserScript==
// @name		rsget.pl
// @namespace	http://rsget.pl/
// @description	Quickly add links to rsget.pl http interface (you must enable it first by setting http-port).
// @include		http://*/*
// @include		https://*/*
// @include		file://*
// ==/UserScript==

/*** {{{ Configuration {{{ ***/
/* 
 * You can edit those values manually, but you should better use configuration
 * page instead: http://rsget.pl/tools/userscript/
 */

// Where your rsget.pl can be found; default: 'http://localhost:7666/'
var server = '<?= $host /* TODO: escape '' chars */ ?>';

// Open menu on all supported pages (including flash-based); default: false
var always_open_supported = <?= $open ? "true" : "false" ?>;

// Are you using UZBL ? If so, enable uzbl-specific hacks; default: false
var uzbl_hacks = <?= $uzbl ? "true" : "false" ?>;

/*** }}} End configuration }}} ***/
/*
 * You shouldn't have to change anything below.
 */


/* supported links {{{ */
/* update supported lists:
awk '/}/ { p = 0 } { if ( p ) { sub(/\t"/, ""); sub( /".+/, "" ); print } } /supported[23] =/ { p = 1 }' \
	< src/tools/userscript/config.php > l.old
grep uri: svn/{Audio,Get,Image,Link,Video}/* | sed 's/.*qr{//; s#/.*##; s/\\\././g; s/(?.\+)?\?//; /\..*\./d' | sort -u > l.new
grep uri: svn/{Audio,Get,Image,Link,Video}/* | sed 's/.*qr{//; s#/.*##; s/\\\././g; s/(?.\+)?\?//; /\..*\./!d' | sort -u >> l.new
diff -u l.old l.new
 */
var supported2 = {
	"4gk.com":	1,
	"4shared.com":	1,
	"anonym.to":	1,
	"archiv.to":	1,
	"badongo.com":	1,
	"bitroad.net":	1,
	"break.com":	2,
	"crypted.biz":	1,
	"crypt-it.com":	1,
	"dailymotion.com":	2,
	"dailymotion.pl":	2,
	"depositfiles.com":	1,
	"easy-share.com":	1,
	"extremetube.com":	2,
	"filefactory.com":	1,
	"freakshare.net":	1,
	"gigasize.com":	1,
	"goear.com":	2,
	"hotfile.com":	1,
	"imageshack.us":	2,
	"linkhider.com":	1,
	"link-protector.com":	1,
	"liveleak.com":	2,
	"lix.in":	1,
	"mediafire.com":	1,
	"megaporn.com":	2,
	"megarotic.com":	1,
	"megaupload.com":	1,
	"megavideo.com":	2,
	"metacafe.com":	2,
	"multiupload.com":	1,
	"netload.in":	1,
	"pornhub.com":	2,
	"protectlinks.com":	1,
	"przeklej.pl":	1,
	"rapidshare.com":	1,
	"rapidshark.pl":	1,
	"redtube.com":	2,
	"rsprotect.com":	1,
	"secured.in":	1,
	"sendspace.com":	1,
	"sendspace.pl":	1,
	"sexuploader.com":	1,
	"sharebee.com":	1,
	"shareplace.com":	1,
	"shareplace.org":	1,
	"sharingmatrix.com":	1,
	"spankwire.com":	2,
	"storage.to":	1,
	"tinyurl.com":	1,
	"turbobit.net":	1,
	"turbobit.ru":	1,
	"turboupload.com":	1,
	"ul.to":	1,
	"uploaded.to":	1,
	"uploading.com":	1,
	"veoh.com":	2,
	"vimeo.com":	2,
	"x7.to":	1,
	"xhamster.com":	2,
	"xurl.jp":	1,
	"youporn.com":	2,
	"youtube.com":	2,
	"zippyshare.com":	1,
	"zshare.net":	1
};

var supported3 = {
	"d01.megashares.com":	1,
	"save.raidrush.ws":	1,
	"tv.delfi.ee":	2,
	"video.banzaj.pl":	2,
	"video.google.com":	2,
	"video.interia.pl":	2
};
/* }}} */

/* tools: async, el {{{ */
function async( f )
{
	window.setTimeout( f, 0 );
}

function el( tag, attrib )
{
	var el = document.createElement( tag );

	if ( attrib )
		for ( var name in attrib )
			el.setAttribute( name, attrib[ name ] );

	return el;
}

function tn( str )
{
	return document.createTextNode( str );
}

function stop_propagation( ev )
{
	ev.stopPropagation();
}

var _cnt = 1;
function cnt()
{
	return ++_cnt;
}
/* }}} */

var finder = { /* {{{ */
	page_supported: false,
	page_location: document.location.href,

	_text_tags: [ "pre", "div", "td", "p", "span", "code", "li" ],
	_text_i: 0,
	_text_nodes: null,
	_a_i: 0,
	_a_nodes: 0,
	links: new Array(),
	link_nodes: new Array(),

	init: function ()
	{
		var bases = document.getElementsByTagName( 'base' );
		for ( var i = 0; i < bases.length; i++ ) {
			var href = bases[ i ].getAttribute( 'href' );
			if ( href )
				finder.page_location = href;
		}
		if ( finder.page_supported = finder._check_support( finder.page_location ) ) {
			menu.init();
		}
		finder._get_text();
	},

	_get_text: function ()
	{
		finder._text_i = 0;
		finder._text_nodes = null;
		if ( ! finder._text_tags.length )
			return finder._get_a();

		finder._text_nodes = document.getElementsByTagName(
			finder._text_tags.shift()
		);
		async( finder._check_text );
	},
	_check_text: function ()
	{
		if ( finder._text_i >= finder._text_nodes.length )
			return finder._get_text();

		var text_node = finder._text_nodes[ finder._text_i++ ];
		async( finder._check_text );

		var node = text_node.firstChild;
		if ( ! node )
			return;

		var found = false;

		do {
			if ( node.nodeName != '#text' )
				continue;
			var text = node.nodeValue;
			if ( text == null || text.length < 15 )
				continue;

			var hrefs = text.match( /(http:\/\/\S+\/\S+)/g );

			if ( ! hrefs || hrefs.length <= 0 )
				continue;

			for ( var i = 0; i < hrefs.length; i++ ) {
				var href = hrefs[ i ];
				if ( ! finder._check_support( href ) )
					continue;
				var start = text.indexOf( href );
				if ( start < 0 )
					continue;

				text_node.insertBefore(
						tn( text.substr( 0, start ) ),
						node );

				/* class is a special word, must have quotes */
				var a = el( 'a', { href: href, 'class': 'get_link_text' } );
				a.addEventListener( 'DOMActivate', finder._click, false );
				a.addEventListener( 'click', finder._click, false );
				a.appendChild( tn( href ) );
				text_node.insertBefore( a, node );

				text = text.substr( start + href.length );
				node.nodeValue = text;

				found = true;
			}
		} while ( node = node.nextSibling );

		if ( found )
			menu.init();
	},

	_get_a: function ()
	{
		finder._a_i = 0;
		finder._a_nodes = document.getElementsByTagName( 'a' );
		async( finder._check_a );
	},
	_check_a: function ()
	{
		if ( finder._a_i + 10 < finder._a_nodes.length )
			async( finder._check_a );
		else {
			async( finder._end );
		}

		for ( var i = 0; i < 10; i++, finder._a_i++ ) {
			if ( finder._a_i >= finder._a_nodes.length )
				break;

			try {
				finder._add_a( finder._a_i );
			} catch( e ) {
				GM_log( "error: " + e );
			}
		}
	},
	_add_a: function( i )
	{
		var a = finder._a_nodes[ i ];
		var cl = a.getAttribute( 'class' );
		if ( cl && cl == 'get_link_text' ) {
			finder._link( a );
			return;
		}

		var href = a.getAttribute( 'href' );
		if ( href == null )
			return;

		if ( finder._check_support( href ) ) {
			a.setAttribute( 'class',
				cl == null ? 'get_link' : cl + ' get_link' );
			finder._link( a );
		} else if ( finder.page_supported ) {
			var m = href.match( /^[a-zA-Z0-9]+:/ );
			if ( !m || m.length < 1 ) {
				if ( href.indexOf( "/" ) == 0 ) {
					m = finder.page_location.match( /^(.*?\/\/.*?)\// );
					href = m[ 1 ] + href;
				} else {
					m = finder.page_location.match( /^(.*?\/\/.*\/)/ );
					href = m[ 1 ] + href;
				}
				a.setAttribute( 'class',
					cl == null ? 'get_link' : cl + ' get_link' );
				a.setAttribute( 'href', href );
				finder._link( a );
			}
		}
	},
	_end: function ()
	{
		finder._a_i = 0;
		finder._a_nodes = null;
		if ( finder.page_supported  )
			if ( always_open_supported || finder.page_supported == 1 )
				menu.open();
	},
	_link: function ( a )
	{
		if ( finder.links.length == 0 )
			menu.init();

		finder.links.push( a.getAttribute( 'href' ) );
		finder.link_nodes.push( a );
	},
	_check_support: function ( href )
	{
		var m = href.match( /http:\/\/.*?([a-z0-9-]+\.[a-z]{2,3})\// );
		if ( m && m.length ) {
			var s = supported2[ m[1] ];
			if ( s )
				return s;

			var m = href.match( /http:\/\/.*?([a-z0-9-]+\.[a-z0-9-]+\.[a-z]{2,3})\// );
			if ( m && m.length ) {
				s = supported3[ m[1] ];
					return s;
			}
		}

		return 0;
	},
	_click: function ( ev )
	{
		ev.stopPropagation();
		ev.preventDefault();

		var get = server + "add?links=" + escape( this.getAttribute( 'href' ) )
			+ ";comment=" + escape( "source: " + document.location.href );
		try {
			GM_openInTab( get );
		} catch ( e ) {
			window.open( get, "_blank" )
		}
	}
}; /* }}} */

var selection = { /* {{{ */
	init: function ()
	{
		document.addEventListener( 'mouseup', selection._check_ev, false );
		document.addEventListener( 'keyup', selection._check_ev, false );
	},
	get: function ()
	{
		var sel = window.getSelection();
		var links = [];
		if ( sel.isCollapsed === true )
			return links;
		var srclinks = finder.link_nodes;
		var len = srclinks.length;
		for ( var i = 0; i < len; i++ ) {
			if ( sel.containsNode( srclinks[ i ], true ) )
				links.push( srclinks[ i ].getAttribute( 'href' ) );
		}

		return links;
	},
	_check_ev: function ( ev )
	{
		if ( menu.manual_open )
			async( menu.open );
		else
			async( selection._check );
	},
	_check: function ()
	{
		var l = selection.get();

		if ( l.length )
			menu.open();
		else
			menu.close();
	}
}; /* }}} */

var menu = { /* {{{ */
	_interval: null,	// toggling interval
	_opened: false,	// is menu opened ?
	_move: 10,		// opening/closing movement
	_width: 0,		// actual menu width
	_box: null,		// container node
	_initialized: false,	// is menu shown ?
	manual_open: false,
	init: function ()
	{
		if ( menu._initialized )
			return;
		menu._initialized = true;

		var css = getCss();
		try {
			GM_addStyle( css );
		} catch ( e ) {
			var cssEl = el( 'link', { rel: 'stylesheet', type: 'text/css',
				href: 'data:text/css,' + encodeURIComponent( css ) } );
			var head;
			if ( head = document.getElementsByTagName('head')[0] ) {
				head.appendChild( cssEl );
			} else {
				var doc = document.documentElement;
				doc.insertBefore( cssEl, doc.firstChild );
			}
		}

		var body = document.getElementsByTagName( 'body' )[0];

		menu._box = el( 'div', { id: 'rsget_pl' } );
		var button = el( 'span' );
		menu._box.appendChild( button );

		body.appendChild( menu._box );

		menu._box.addEventListener( 'DOMActivate', stop_propagation, false );
		menu._box.addEventListener( 'click', stop_propagation, false );
		button.addEventListener( 'DOMActivate', menu._toggle_ev, false );
		button.addEventListener( 'click', menu._toggle_ev, false );
		window.addEventListener( 'scroll', menu._update_position, false );

		async( selection.init );
		async( menu._update_position );
	},
	_toggle_ev: function ( ev )
	{
		ev.stopPropagation();
		ev.preventDefault();
		async( menu._toggle );
	},
	_toggle: function ()
	{
		if ( menu._opened ) {
			menu.manual_open = false;
			menu.close();
		} else {
			menu.manual_open = true;
			menu.open();
		}
	},
	_disable_ev: function ( ev )
	{
		ev.stopPropagation();
		ev.preventDefault();
		// XXX: this is ugly
		document.location = document.location.href + "#no_rsget";
		document.location.reload();
	},
	open: function ()
	{
		menu.init();

		var rm = menu._box.lastChild;
		if ( rm.nodeName == 'DIV' )
			menu._box.removeChild( rm );

		var div = el( 'div' );
		var ul = el( 'ul' );

		{
			var li = el( 'li' );

			var a = el( 'a', { href: "#no_rsget" } );
			a.addEventListener( 'DOMActivate', menu._disable_ev, false );
			a.addEventListener( 'click', menu._disable_ev, false );
			a.appendChild( tn( "close" ) );
			li.appendChild( a );

			var buttons = [
				"config", "http://rsget.pl/tools/userscript/",
				"interface", server,
				"web", "http://rsget.pl/"
			];

			for ( var i = 0; i < buttons.length; i+=2 ) {
				li.appendChild( tn( ", " ) );

				a = el( 'a', { href: buttons[ i + 1 ] } );
				a.appendChild( tn( buttons[ i ] ) );
				li.appendChild( a );
			}

			ul.appendChild( li );
		}

		if ( finder.page_supported ) {
			ul.appendChild( menu._li_form(
				[ document.location.href ],
				window.top.location.href,
				"add this page to rsget.pl"
			) );
		}
		if ( finder.links.length ) {
			ul.appendChild( menu._li_form(
				finder.links,
				document.location.href,
				"add the only link to rsget.pl",
				"add all %d links to rsget.pl"
			) );

			var l = selection.get();
			if ( l.length )
				ul.appendChild( menu._li_form(
					l,
					document.location.href,
					"add selected link to rsget.pl",
					"add %d selected links to rsget.pl"
				) );
		}

		div.appendChild( ul );
		menu._box.appendChild( div );

		if ( menu._opened )
			return;
		menu._move = +10;
		if ( ! menu._interval )
			menu._interval = window.setInterval( menu._slide, 20 );
		menu._opened = true;
	},
	close: function ()
	{
		if ( ! menu._opened || menu.manual_open )
			return;
		menu._move = -10;
		if ( ! menu._interval )
			 menu._interval = window.setInterval( menu._slide, 20 );
		menu._opened = false;
	},
	_slide: function ()
	{
		menu._width += menu._move;
		if ( menu._move > 0 ) {
			if ( menu._width >= 250 ) {
				menu._width = 250;
				window.clearInterval( menu._interval );
				menu._interval = null;
			}
		} else {
			if ( menu._width <= 0 ) {
				menu._width = 0;
				window.clearInterval( menu._interval );
				menu._interval = null;

				var rm = menu._box.lastChild;
				if ( rm.nodeName == 'DIV' )
					menu._box.removeChild( rm );
			}
		}

		menu._box.style.width = ( 16 + menu._width ) + "px";
		menu._box.style.opacity = 0.2 + menu._width * 0.003;
	},
	_update_position: function ( ev )
	{
		var y = window.pageYOffset || document.documentElement.scrollTop || 0;
		menu._box.style.top = ( y + 100 ) + "px";
	},
	_li_form: function ( links, source, text1, textN )
	{
		var ltext = links.join( "\n" );
		var text = links.length == 1 ? text1 : textN.replace( /%d/, links.length );

		var form = el( 'form', { action: server + "add#cnt_" + cnt(),
				method: 'POST' } );
		/* Currently uzbl is unable to send POST request in new window. */
		if ( ! uzbl_hacks )
			form.setAttribute( 'target', '_blank' );

		form.appendChild( el( 'input', { type: 'hidden',
			name: 'links', value: ltext } ) );
		form.appendChild( el( 'input', { type: 'hidden',
			name: 'comment', value: "source: " + source } ) );
		form.appendChild( el( 'input', { type: 'submit', value: text } ) );

		var li = el( 'li' );
		li.appendChild( form );

		return li;
	}
}; /* }}} */

function getCss() /* {{{ */
{
	var png_hook = 'url(data:image/png;base64,'
		+ 'iVBORw0KGgoAAAANSUhEUgAAACAAAAAQCAYAAAB3AH1ZAAAAAXNSR0IArs4c6QAAAxVJREFUSMe9'
		+ 'lM9rFGcYxz/vZjbJxrWMeCjehlzMQdJAcijoRWRvxbOgsDc39paDRNmCJTXI/AHC5LinHARPHoQh'
		+ 'IJU9GTFYlMTDMhQstmXjJDtxdmdn3rcH39nOjLHuofiF4WWe98fzfJ/n+zxizTDKF9fWyks3bshp'
		+ '0yRFFAS4N2+y7ThCm9JV3VFKARJQ+gMQ3pMnpc3Ll1XU6+X2pk2TxosXmJZFARPG/LVrUxdu3/4G'
		+ 'qABlYAIQHdct7bRa6H8JlABMy0r0f5xdoyAQz+7fF1GvB5CekUIItbS8rLRzlXGufM+LjO9XVgzg'
		+ 'BHAKmAEM3/PEVrNJHIa5cIUQnLtyRWXYjVh2XJc3jx6NHtcZk9UzZ0qLjYbM2AGGURB027b9h/Ht'
		+ '/LwADGAKmIqCwGjbtuju7mYvCIDTc3MsNhoUUo/veWw1m8T9fj7gUonF69eLqVfA+47rvt9ptUKj'
		+ 'UF/RcV2x02rxscwjO0alwqX19fQxkd17vrFBd2+vWF9Onz3Ld/V60dz3Pe/vrWbz4KcwlKVsakZM'
		+ 'jkn9Qr3ObK32iRPf89h2HJSUOXsh4BQS6D7f2HjX3duLSYX1RSZzc5xfXWWyWs3ZoyCgbdv0ff+T'
		+ 'O8cErIAD3/PebjvOhztSKnTtlVak2nYcNSYTUuHpTslh2jSLAUugFwXB723b3r/l+yP9GJqJaNu2'
		+ '6Pu+GIMJXyrX0vIymbaLgB7wtuO6f/3gOHGOYIaJKvTpcUzGKpduuwQIgQPgXRQE+0/v3YuL57M9'
		+ 'n1N2gck4wpNGpaIura8PTcsaAEfAvv6Opk6eTDgGxq9379Ld3RWfYVIUUSo81f9Yx5RpAkQL9fpg'
		+ 'tlY7AgLgUGdgKIRQfAbG6wcPUP/O9hhQGeGlMz11knRcN9lptdKzMTAEwmnTHJxfXQ0nq9WBrrv8'
		+ 'L8ejAAaHhwnQ10IZABML9XoyW6tJ/Xik7dGfL18OH6+sxHEYxpl5n+h5L03LUuM4zYn2l8nJchJF'
		+ 'hp4JojwzI3589QrTsrLMJSAfXr2qftvcBKX4uSDY/xVKKaGUEnwF/AP+JrSClDIuFgAAAABJRU5E'
		+ 'rkJggg=='
		+ ')';

	var png_rsget_red = 'url(data:image/png;base64,'
		+ 'iVBORw0KGgoAAAANSUhEUgAAABAAAABACAMAAAAkowekAAAAAXNSR0IArs4c6QAAAGBQTFRFdxAP'
		+ 'fBYYgBsggCMihCclhzAvizUyjjg6kEA/l0pLm1FRnVlXo19ho2VkqmtqrHNysHp7uY2Lw52fyaan'
		+ '0ba018PF2czM3tHS5NnZ5eDe6ubk6Orn8Orp6+7q7e/r8PLvnUVSCwAAAfFJREFUOMtNU4m2qyAQ'
		+ 'G9zrdsW2VKWE///LN4vax+nCic6QSQIlZABJv/ybiHeR/zOigIAAaBtbyYAEOpfUKDDx6p0bY+KH'
		+ '0oj7pvSmxXokqZSTmlJ7aG8+IX3b+tBjGdnDnvfXR97LJBQG2kJJ9NQS7oe6TX/kqJP2Qiy5AQ/a'
		+ 'OqdAToiuR1lhcNwk67E1PahHW8l4OsvCtNedMSMGHH703yNsCkQdOjyfISphwstvRy+z9rtoROjK'
		+ 'Y7TpRzmAwGc6Wt5vpgadhQaUtQzA04pAqSr3xW0ZW7EogJGq0RXDWLjJVA+Obk2NWJgu1XErpj7d'
		+ 'vogiYV1DypdR8TtJh+l7O+etp8fpLVryE62uUedEFNexJOidCiRDs6YLfZsiXz3qJi3UsGL5MpsC'
		+ 'q1iErOMz8PYv380fU8z4iQGaI34jWriAsb2JHX7mVdI8n8DwE0CcY2+p4uEdiQBqNjXSpuOH0Uo4'
		+ 'CCwHAxCA7Q8fIf1c72k1c9l2SmyeV2PFNaSoJCHrRwFU1ZQzv5HyGRhRXBPNgaWMnwVaDrWo1a/d'
		+ 'BvotA+RuuHIYaw7MKTI4DkhH8weLNjQwiIMFRuokUsE7p/mQA+/QXXHYH2csmRBZOCQOJrX2yMLc'
		+ '6FtgzkQJX7uV/5G1Szj91jn+FTztkc+tWM/bfzTpViSa6M6aAAAAAElFTkSuQmCC'
		+ ')';

	var png_rsget_black = 'url(data:image/png;base64,'
		+ 'iVBORw0KGgoAAAANSUhEUgAAABAAAABACAMAAAAkowekAAAAAXNSR0IArs4c6QAAAGBQTFRFAAAA'
		+ 'CQkJERERGBgYIyMjKSkpMzMzOTk5Q0NDS0tLUVFRWVlZYGBgZ2dnbm5ud3d3goKChoaGkZGRm5ub'
		+ 'n5+fqKiosLCwuLi4vb29xcXFysrK09PT29vb4+Pj7e3t7u7uUvegfQAAAalJREFUOMtVU4mWgzAI'
		+ 'JJdVk9pau4c2wv//5ZKQw+W1HhMDMwMBpBSY/3xFAMh3/slSAsiVQAEwXXKkDzPgOUalPGJelIy4'
		+ 'w0J1i4TVWJOmCojOnqUsxeOk+P3pZSf4HBrg3cpahwsoGEpZQjXRDeKgGgAjGcMbW1kLN8acSfJy'
		+ '0gdfX5GxWuV8ziueR2wA0fF+H03++jmnpHU6k0f8oE8v6j2J2pEULL+/d1AkWibSNlGyBoWYjg/F'
		+ 'BaJ+FADMrPQ0a3ZMtihonkrZwzsr0YmJq90gpGPbOlNey8wCti9WyblSNdnBM8CmXOucGmgBGlUz'
		+ 'iD1dAJ1uObLrlkVVTz3sC2vai3yk/fmzDuHSuRq12Xm4iLzrrq/3EIKBEFqzuwHSWzAsXkEyQHpr'
		+ 'U5oBSllGh2THkI3IPI5M4evV1F4jA+H+ElbMoJQaG9kMGONl/qsfeU7LkWjAJalrUTztUQA+G6nZ'
		+ 'BmZqU8jjgKe7N2ImDQxOuswH5ZHaV6XqqaRZcs5tSxzT+xgLsURq37ad8DowWOj/P8iJ7L+DnF7y'
		+ 'F77HpZVFMPRHzJb8Aci0Sidb/wCCAAAAAElFTkSuQmCC'
		+ ')';

	var css = "\
a.get_link, a.get_link_text {\
	background: " + png_hook + " no-repeat;\
}\
a.get_link_text {\
	font: inherit;\
	color: inherit;\
	text-decoration: inherit;\
}\
a.get_link_text:hover {\
	text-decoration: underline;\
}\
div#rsget_pl {\
	position: absolute;\
	right: 0px;\
	top: 100px;\
	height: 64px;\
	width: 16px;\
	border: 2px solid #fff;\
	background: #eee;\
	z-index: 32766;\
	opacity: 0.2;\
	overflow: hidden;\
}\
div#rsget_pl * {\
	font-family: \"Bitstream Vera Sans\", \"Free Sans\", \"FreeSans\",\
		\"DejaVu Sans Condensed\", \"Droid Sans\", sans-serif;\
	font-size: 13px;\
	line-height: 13px;\
	color: #222;\
	padding: 0;\
	margin: 0;\
	border: 0;\
	background: transparent;\
	text-decoration: none;\
	visibility: visible;\
	display: inline;\
}\
div#rsget_pl div {\
	position: relative;\
	display: block;\
}\
div#rsget_pl ul {\
	list-style-type: none;\
	width: 250px;\
	right: 0;\
	position: absolute;\
	display: block;\
}\
div#rsget_pl li {\
	text-align: right;\
	display: list-item;\
}\
div#rsget_pl input[type=submit], div#rsget_pl a {\
	margin-top: -1px;\
	margin-bottom: -1px;\
	display: inline;\
	border-bottom: 1px solid transparent;\
	color: #711;\
	cursor: pointer;\
}\
div#rsget_pl input[type=submit]:hover, div#rsget_pl a:hover {\
	color: #000;\
	border-bottom: 1px solid #000;\
}\
div#rsget_pl span {\
	float: left;\
	height: 64px;\
	width: 16px;\
	display: block;\
	cursor: pointer;\
	display: block;\
	background: " + png_rsget_red + ";\
}\
div#rsget_pl span:hover {\
	background: " + png_rsget_black + ";\
}"
	;

	return css;
} /* }}} */

function start()
{
	window.setTimeout( finder.init, 500 );
}

(function ()
{
	if ( document.location.hash == "#no_rsget" )
		return;

	if ( document.documentElement )
		start();
	else
		window.addEventListener( 'load', start, false );
})();

// vim: ts=4:sw=4:filetype=javascript:fdm=marker
