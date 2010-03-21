/*
 * 2010 (c) Przemysław Iskra <sparky@pld-linux.org>
 *
 * NOTE: This script is _NOT_ free software, please ask me permission
 *       if you want to reuse it or some portions. I will most likely
 *       allow it.
 *
 */

function column_position( num )
{
	return 620 * num;
}

var loglevel = 0;

var xmlns = "http://www.w3.org/1999/xhtml";

var e = {
	html: null,
	body: null,
};

function el( tag, cl, attrib ) /* {{{ */
{
	var el = document.createElementNS( xmlns, tag );

	if ( cl )
		el.setAttribute( 'class', cl );

	if ( attrib && typeof attrib === 'object' )
		for ( var name in attrib )
			el.setAttribute( name, attrib[ name ] );

	return el;
}
/* }}} */

/* wrap functions for handlers whitch change "this" object */
function anon_func( func, object )
{
	return function() {
		return func.apply( object, arguments );
	}
}

function func_noargs( func, object )
{
		return func.call( object )
}
function func_apply( func, object, args )
{
		return func.apply( object, args )
}
function func_call( )
{
	var args = Array.prototype.slice.call( arguments );
	var func = args.shift();
	var object = args.shift();
	return func.apply( object, args )
}

/* {{{ async: call function just after finishing code block */
function async( )
{
	var args = Array.prototype.slice.call( arguments );
	var func = args.shift();
	if ( !func )
		return error( "Function missing" );

	window.setTimeout( func_apply, 0, func, this, args );
}
/* }}} */

/* {{{ timeSlicer: call callback function in short intervals, until endAfter */
/* var ts = timeSlicer( );
 *	callback = function( time ) { this = object }
 *	end = function( time ) { this = object }
 *	endAfter - time in ms
 *	object - this in callback functions
 * ts.end();
 */
function timeSlicer( callback, end, endAfter, object )
{
	this._start = new Date().valueOf();
	this._callback = callback;
	this._callbackEnd = end;
	this.end = function () {
		window.clearInterval( this._interval );
		this._callbackEnd.call( this._object, this._endAfter )
	}
	this._endAfter = endAfter;
	this._object = object;
	this._interval = window.setInterval( timeSlicer_call, 20, this );
}

function timeSlicer_call( t )
{
	var time = new Date().valueOf();
	var change = time - t._start;
	if ( change > t._endAfter ) {
		t.end();
	} else {
		t._callback.call( t._object, change )
	}
}
/* }}} */

/* {{{ message system */
/* requires: timeSlicer */
var msg = {
	_board: null,
	_fadeTime: 1000,
	_holdTime: 10000,
	add: function ( text, cl )
	{
		if ( !msg._board ) {
			msg._board = document.getElementById( "_msgBoard" );
			if ( !msg._board ) {
				if ( cl == "error" )
					window.alert( "Error: " + text );
				return;
			}
		}

		var p = el( 'p', cl );
		p.appendChild( document.createTextNode( text ) );
		p.style.opacity = 0;
		msg._board.appendChild( p );
		msg._board.style.display = "block";

		new timeSlicer( msg._opacityUp, msg._opacityFix, msg._fadeTime, p );
	},
	_opacityUp: function ( time )
	{
		this.style.opacity = time / msg._fadeTime;
	},
	_opacityFix: function ( time )
	{
		this.style.opacity = 1;
		window.setTimeout( msg._startRemove, msg._holdTime, this );
	},
	_startRemove: function ( p )
	{
		new timeSlicer( msg._opacityDown, msg._remove, msg._fadeTime, p );
	},
	_opacityDown: function ( time )
	{
		this.style.opacity = 1 - time / msg._fadeTime;
	},
	_remove: function ( time )
	{
		this.parentNode.removeChild( this );
		if ( ! msg._board.firstChild )
			msg._board.style.display = "none";
	}
};

function log( level, text )
{
	if ( loglevel >= level )
		msg.add( text, "log" );
}

function logFunc( args, func )
{
	if ( loglevel < 5 )
		return;

	var ar = Array.prototype.slice.call( args );
	var text = "" + ( func || args.callee.name ) + "( "
		+ ar.map( function( a ) {
			if ( typeof a == "undefined" )
				return "undef";
			if ( typeof a == "string" )
				return '"' + a + '"';
			var v;
			try {
				v = a.toSource();
			} catch ( e ) {
				v = e;
			}
			return v;
		} ).join( ", " ) + " )";
	msg.add( text, "log" );
}

function print( text )
{
	msg.add( text );
}

function error( text )
{
	msg.add( text, "error" );
}

/* }}} */

/* {{{ blink */
/*
 * blink.start();
 * blink.stop();
 */
var blink = {
	_interval: null,
	_do_stop: false,
	_node1: null,
	_node2: null,
	_angle: 0,
	_id: {},
	_change: function( )
	{
		var time = new Date().valueOf();
		this._angle += ( time - this._last ) * 0.006;
		this._last = time;
		var opacity = ( Math.sin( this._angle ) + 1 ) / 2;

		if ( this._do_stop ) {
			if ( opacity < 0.05 ) {
				this._node1.style.display = "none";
				this._do_stop |= 1;
			} else if ( opacity > 0.95 ) {
				this._node2.style.display = "none";
				this._do_stop |= 2;
			}
			if ( ( this._do_stop & 3 ) == 3  ) {
				this._do_stop = 0;
				window.clearInterval( this._interval );
				opacity = 0.5;
				this._interval = null;
			}
		}
		this._node1.style.opacity = opacity;
		this._node2.style.opacity = 1 - opacity;
	},
	init: function( )
	{
		this._node1 = document.getElementById( "_lightL" );
		this._node2 = document.getElementById( "_lightR" );
		this._node1.style.display = "none";
		this._node2.style.display = "none";
	},
	start: function( )
	{
		logFunc( arguments, "blink.start" );

		var id = 1;
		while ( this._id[ id ] )
			id++;
		this._id[ id ] = 1;

		this._do_stop = 0;
		this._node1.style.display = "block";
		this._node2.style.display = "block";
		if ( this._interval )
			return id;

		this._angle = - Math.PI / 2;
		this._last = new Date().valueOf();
		this._interval = window.setInterval( func_noargs, 50, this._change, this );
		return id;
	},
	stop: function( id )
	{
		logFunc( arguments, "blink.stop" );
		if ( ! this._id[ id ] )
			return;

		delete this._id[ id ];

		var empty = true;
		for ( var id in this._id ) {
			empty = false;
			break;
		}

		if ( ! empty )
			return;

		if ( ! this._do_stop )
			this._do_stop |= 4;
	}
};

function blinker()
{
	this._id = blink.start();
	this.stop = function()
	{
		logFunc( arguments, "blinker.stop" );
		blink.stop( this._id );
	};
}
/* }}} */

/* {{{ screenMove.go: move screen to desired x, y position  */
var screenMove = {
	_queueX: null,
	_queueY: null,
	_delayId: null,
	_move: function ( time )
	{
		var angle = time * this._mult;
		var c = ( 1 - Math.cos( angle ) ) * 0.5;

		var x = this._startX + this._diffX * c;
		var y = this._startY + this._diffY * c;
		window.scrollTo( x|0, y|0 );
	},
	_end: function ( time )
	{
		window.scrollTo( this._endX, this._endY );
		if ( this._queueX != null ) {
			this._start();
		} else
			this._delayId = null;
	},
	_start: function ( )
	{
		this._endX = this._queueX;
		this._endY = this._queueY;
		this._queueX = null;
		this._queueY = null;

		/*
		var maxX = e.html.scrollWidth - e.html.clientWidth;
		var maxY = e.html.scrollHeight - e.html.clientHeight;
		*/

		if ( this._endX < 0 )
			this._endX = 0;
		/*else if ( this._endX > maxX )
			this._endX = maxX;*/

		if ( this._endY < 0 )
			this._endY = 0;
		/*else if ( this._endY > maxY )
			this._endY = maxY;*/

		this._startX = window.pageXOffset || e.html.scrollLeft;
		this._startY = window.pageYOffset || e.html.scrollTop;
		if ( this._startX == this._endX && this._startY == this._endY ) {
			this._delayId = null;
			return;
		}
		this._diffX = this._endX - this._startX;
		this._diffY = this._endY - this._startY;
		var time = 2 * Math.sqrt( this._diffX * this._diffX + this._diffY * this._diffY );
		time = time < 1000 ? 1000 : time > 2000 ? 2000 : time;
		this._mult = Math.PI / time;

		new timeSlicer( this._move, this._end, time, this );
	},
	go: function ( endX, endY )
	{
		logFunc( arguments, "screenMove.go" );
		this._queueX = endX;
		this._queueY = endY;
		if ( ! this._delayId )
			this._delayId = window.setTimeout( func_noargs, 100, this._start, this );
	}
};
/* }}} */

/* {{{ links + history */
var links = {
	_href: null,
	_hash: null, // no # here
	_now: null,
	decodeHash: function ()
	{
		var d = { page: null, id: null, hash: null };

		var m = document.location.hash.match( /^#(\/.*?)?(#(.+))?$/ );
		if ( m && m.length ) {
			d.page = m[1];
			d.id = m[3];
		} else {
			var m = document.location.hash.match( /^#(.+)$/ );
			if ( m && m.length )
				d.id = m[1];
		}
		if ( ! d.page )
			d.page = document.location.pathname;
		if ( ! d.id )
			d.id = null;

		d.hash = d.id ? "#" + d.id : "";

		return d;
	},
	encodeHash: function ( page, id )
	{
		var hash = "#" + page;
		if ( id )
			hash += "#" + id;

		return hash;
	},
	event: function ( event )
	{
		event.stopPropagation();
		event.preventDefault();

		var href = this.getAttribute( "href" );
		links.change( href );
	},
	change: function ( link )
	{
		logFunc( arguments, "links.change" );
		var m = link.match( /^(\/.*?)?(#(.+))?$/ );
		if ( m[1] )
			this._href = m[1];
		this._hash = m[3] || null;

		var nowhash = "#" + (this._href || "");
		if ( this._hash )
			nowhash += "#" + this._hash;

		document.location.hash = nowhash;
		this._now = nowhash;

		columns.change( this._href, this._hash );
		return;
	},
	find: function( doc )
	{
		logFunc( arguments, "links.find" );
		var as = doc.getElementsByTagName( "a" );
		for ( var i = 0; i < as.length; i++ ) {
			var a = as[ i ];
			var href = a.getAttribute( "href" );
			if ( !href )
				continue;
			var m = href.match( /^(\/(.*?\/)?)?(#.+)?$/ );
			if ( m ) {
				a.addEventListener( "DOMActivate", links.event, false );
				a.addEventListener( "click", links.event, false );
			}
		}
	},

	init: function( )
	{
		window.setInterval( func_noargs, 200, this._check, this );
		this._now = "";
	},
	_check: function( )
	{
		var hash = document.location.hash;
		if ( hash == this._now )
			return;

		log( 1, "history trigger: " + hash + " (" + this._now + ")" );

		this._now = hash;

		var m = hash.match( /^#(.*)$/ );
		this.change( m ? m[1] : document.location.pathname );
	}


};
/* }}} */

/* {{{ columns */
var columns = {
	/* list of loaded columns (names) */
	_loaded: null,
	/* list of columns to load (names) */
	_goto: null,
	/* dom trees cache (name: dom)*/
	_cached: {},
	/* object id to go to, no # */
	_hash: null,

	_counter: 0,
	_last_is_remove: false,

	async: async,
	init: function( uri )
	{
		logFunc( arguments, "columns.init" );
		var m = document.location.pathname.match( "^/(.*?)/?$" );
		if ( !m || m.length < 1 ) {
			error( "Cannot determine columns loaded" );
			columns._loaded = [];
			return;
		}

		columns._loaded = columns._split( m[1] );
		log( 2, "Columns loaded: " + columns._loaded );
		columns.async( columns._initCache );
	},
	_initCache: function()
	{
		logFunc( arguments, "columns._initCache" );
		for ( var i = 0; i < this._loaded.length; i++ ) {
			var colname = this._loaded[ i ];
			var col = document.getElementById( "_column" + i );
			if ( col )
				this._cached[ colname ] = col;
		}
	},
	_split: function( dir )
	{
		var s = dir.split( "/" );

		var now = "/";
		var dirs = [ now ];
		for( var i = 0; i < s.length; i++ ) {
			if ( s[i] ) {
				now += s[i] + "/";
				dirs.push( now );
			}
		}
		return dirs;
	},
	position: function( col )
	{
		logFunc( arguments, "columns.position" );
		var ret = column_position( col ) - e.html.clientWidth;
		return ret;
	},
	add: function( xml, uri )
	{
		logFunc( arguments, "columns.add" );
		links.find( xml );
		var div = xml.getElementsByTagName( 'div' )[ 0 ];
		div.parentNode.removeChild( div );
		if ( document.adoptNode ) {
			div = document.adoptNode( div );
		} else if ( document.importNode ) {
			div = document.importNode( div, true );
		}
		columns._cached[ uri ] = div;
	},
	_maybeDone: function()
	{
		this._counter = 0;

		this.title();

		var len = this._loaded.length;
		if ( len != this._goto.length )
			return;

		for ( var i = 0; i < len; i++ ) {
			if ( this._loaded[ i ] != this._goto[ i ] )
				return;
		}

		this._goto = null;

		window.clearInterval( this._intervalId );
		this._intervalId = null;

		columns.goToIdOrLast( this._hash );
	},
	_nextState: function()
	{
		this._counter++;
		if ( this._counter < 5 )
			return;

		var remove = false;
		var len = this._loaded.length;
		var matching_columns = 0;
		if ( this._loaded.length > this._goto.length ) {
			remove = true;
			len = this._goto.length;
		}
		for ( var i = 0; i < len; i++ ) {
			matching_columns = i;
			if ( this._loaded[ i ] != this._goto[ i ] ) {
				remove = true;
				break;
			}
		}

		if ( remove ) {
			var colname = this._loaded[ this._loaded.length - 1];
			var col = this._cached[ colname ];
			columnRemove( col );
			if ( col.getAttribute( 'class' ).match( /\s+nocache/ ) ) {
				delete this._cached[ colname ];
			}
			this._loaded.pop();
			columns.goToIdOrColumn( this._hash, matching_columns );
			this._last_is_remove = true;
			return this._maybeDone();
		}

		if ( this._last_is_remove ) {
			if ( this._counter < 20 )
				return;
			this._last_is_remove = false;
		}

		var i = this._loaded.length;
		var colname = this._goto[ i ];
		if ( colname ) {
			var col = this._cached[ colname ];
			if ( col ) {
				columnAdd( col );
				this._loaded.push( colname );
				columns.goToIdOrLast( this._hash );
				return this._maybeDone();
			} else {
				if ( this._counter % 10 == 0 )
					print( "Column " + colname + " not ready" );
			}
		}

		return this._maybeDone();
	},
	change: function( href, hash )
	{
		logFunc( arguments, "columns.change" );
		this._hash = hash;

		this._goto = this._split( href );
		for ( var i = 0; i < this._goto.length; i++ ) {
			var colname = this._goto[ i ];
			if ( typeof this._cached[ colname ] == 'undefined' ) {
				this._cached[ colname ] = null;
				new AJAX( this.add, colname );
			}
		}

		this._counter = 5;
		if ( ! this._intervalId )
			this._intervalId = window.setInterval( func_noargs, 100,
					this._nextState, this );
	},
	_positionIdOrColumn: function( id, col )
	{
		var p = { x: 0, y: 0 };

		var el;
		if ( id )
			el = document.getElementById( id );
		if ( el ) {
			p = this._elPosition( el );
		} else {
			p.x = columns.position( col );
			p.y = 0;
		}

		return p;
	},
	goToIdOrColumn: function( id, col )
	{
		var p = this._positionIdOrColumn( id, col );
		screenMove.go( p.x, p.y );
	},
	goToIdOrLast: function( id )
	{
		var p = this._positionIdOrColumn( id, columns._loaded.length );
		screenMove.go( p.x, p.y );
	},
	jumpToIdOrLast: function( id )
	{
		var p = this._positionIdOrColumn( id, columns._loaded.length );
		window.scrollTo( p.x, p.y );
	},
	_elPosition: function( el )
	{
		var x = 0;
		var y = 0;
		do {
			y += el.offsetTop;
			el = el.offsetParent;
			var id = el.getAttribute( 'id' );
			var m = id.match( /_column(\d+)/ );
			if ( m && m.length > 0 ) {
				x = columns.position( (0|m[1]) + 1 );
				break;
			}
		} while( el );

		return { x: x, y: y };
	},
	title: function( )
	{
		var title = [];

		var len = this._loaded.length;
		for ( var i = 0; i < len; i++ ) {
			var col = this._cached[ this._loaded[ i ] ];
			var h = col.getElementsByTagName( 'h1' )[0];
			title.push( h.firstChild.nodeValue );
		}
		document.title = title.join( ": " );
	}
};
/* }}} */

/* {{{ init */
var init = {
	_maybeSwitchPage: function( )
	{
		if ( window.location.href != document.location.href ) {
			try {
				window.location = document.location.href;
				return true;
			} catch ( e ) {
			}
		}

		var d = links.decodeHash();

		if ( d.page != document.location.pathname ) {
			document.location = d.page + links.encodeHash( d.page, d.id );
			return true;
		}

		document.location.hash = links.encodeHash( d.page, d.id );
		return false;
	},
	_findElements: function( )
	{
		for ( var tag in e ) {
			e[ tag ] = document.getElementsByTagName( tag )[0];
		}
	},
	onload: function( event )
	{
		logFunc( arguments, "init.onload" );
		init._findElements();
		blink.init();

		if ( init._maybeSwitchPage() )
			return;

		columns.init( );

		var m = document.location.hash.match( /^#(\/.*?)?#(.*)$/ );
		columns.jumpToIdOrLast( m ? m[2] : null );

		links.init( );
		links.find( document );
	}
};
window.addEventListener( 'load', init.onload, false );
/* }}} */

function columnRemove( col ) /* {{{ */
{
	logFunc( arguments );
	var move = function ( time ) {
		var angle = ( time - this.time ) * this.mult;
		var left = this.start + 2000 * Math.sin( angle ) + 2000;
		this.col.style.left = (left|0) + "px";
	};
	var end = function ( time ) {
		this.col.parentNode.removeChild( this.col );
	};
	var m = col.getAttribute( "id" ).match( /(\d+)/ );
	var data = {
		start: column_position( m[1] ),
		time: 1000
	};
	data.mult = Math.PI * 0.5 / data.time,
	data.col = col;

	new timeSlicer( move, end, data.time, data );
}
/* }}} */

function columnAdd( col ) /* {{{ */
{
	logFunc( arguments );
	var move = function ( time ) {
		var angle = - time * this.mult;
		var left = this.start + 2000 * Math.sin( angle ) + 2000;
		this.col.style.left = (left|0) + "px";
	};
	var end = function end( time ) {
		this.col.style.left = this.start + "px";
	};

	var id = col.getAttribute( 'id' );
	var m = id.match( /_column(\d+)/ );
	var data = {
		start: column_position( m[1] ),
		time: 1000
	};
	data.mult = Math.PI * 0.5 / data.time;
	data.col = col;

	data.col.style.left = (data.start + 2000) + "px";
	e.body.appendChild( data.col );

	new timeSlicer( move, end, data.time, data );
}
/* }}} */

/* {{{ AJAX */
function AJAX( callback, uri, post )
{
	logFunc( arguments );
	log( 1, "AJAX: " + uri );
	this._callback = callback;
	this._uri = uri;
	this._post = post;
	this._fulluri = this._uri + "_ajax/";
	this._blinker = new blinker();

	/* watchdog */
	this._watchdogTimeout = 5; // 1s ticks
	this._watchdogTime = 0;
	this._watchdogAlarm = function()
	{
		error( "AJAX " + this._uri + " timeout" );

		/* give it more time */
		this._watchdogTimeout += 5;
		if ( this._watchdogTimeout > 20 )
			this._fail( "AJAX timeout" );
		else
			this.restart();
	};
	this._watchdogTick = function()
	{
		this._watchdogTime++;
		if ( this._watchdogTime > this._watchdogTimeout )
			this._watchdogAlarm();
	};
	this._watchdogStart = function()
	{
		this._watchdogId = window.setInterval( func_noargs, 1000,
				this._watchdogTick, this );
	};
	this._watchdogStop = function()
	{
		window.clearInterval( this._watchdogId );
	};


	this._req = new XMLHttpRequest();
	this._onreadystatechange = function ()
	{
		/* it's alive - update watchdog */
		this._watchdogTime = 0;

		var req = this._req;
		if ( req.readyState != 4 )
			return;

		/* in gecko on abort readyState is 4, but status throws an exception */
		var status;
		try {
			status = req.status;
		} catch (e) {
			status = -1;
		}
		if ( status == -1 )
			return;

		if ( status != 200 )
			return this._fail( "Unexpected server response: " + status );

		if ( ! req.responseXML )
			return this._fail( "Not XML" );

		return this._finish();
	};

	this._request = function()
	{
		var onreadystatechange = anon_func( this._onreadystatechange, this );
		if ( this._post && this._post.length > 0 ) {
			this._req.open( "POST", this._fulluri, true );
			this._req.setRequestHeader( 'Content-Type',
				'application/x-www-form-urlencoded' );
			this._req.setRequestHeader( 'Content-Length', this._post.length );
			//this._req.setRequestHeader( 'Connection', 'close' );
			this._req.onreadystatechange = onreadystatechange;
			this._req.send( this._post );
		} else {
			this._req.open( "GET", this._fulluri, true );
			this._req.onreadystatechange = onreadystatechange;
			this._req.send( null );
		}
	};
	this._finish = function()
	{
		logFunc( arguments, "AJAX._finish" );
		this._watchdogStop();
		this._blinker.stop();
		try {
			this._callback( this._req.responseXML, this._uri );
		} catch (e) {
			this._fail( "callback error: " + e );
		}
	};
	this._fail = function( msg )
	{
		error( "AJAX " + this._uri + " failed: " + msg );
		this._watchdogStop();
		this._req.abort();
		this._blinker.stop();
	};
	this.restart = function()
	{
		this._req.abort();
		this._watchdogTime = 0;
		this._request();
	};
	this.abort = function()
	{
		this._watchdogStop();
		this._req.abort();
		this._blinker.stop();
	};

	this._request();
}
/* }}} */

// vi: ts=4 sw=4 noet fdm=marker
