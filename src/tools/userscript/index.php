index:	0
title:	userscript
desc:	Userscript for Mozilla, Chormium, Opera, Epiphany and UZBL web browsers.

body:	
<p>
	This script allows to quickly add links to http interface. Just remember
	to activate the interface (use <tt>--http-port=7666</tt> option).
</p>
<h2>Supported browsers</h2>
<dl>
	<dt><a href="http://www.mozilla.com/firefox/">Firefox</a></dt>
	<dt><a href="http://www.seamonkey-project.org/">SeaMonkey</a></dt>
	<dd><p>To be able to use this script in mozilla browsers you must install
		Greasemonkey; <a href="http://www.greasespot.net/">original version</a>
		for Firefox, or <a href="http://xsidebar.mozdev.org/modifiedmisc.html#greasemonkey">modified version</a> for SeaMonkey.</p></dd>

	<dt><a href="http://www.chromium.org/Home">Chromium</a></dt>
	<dt><a href="http://www.google.com/chrome">Chrome</a></dt>
	<dd><p>You need recent enough version of Chrome for 
		<a href="http://dev.chromium.org/developers/design-documents/user-scripts">user script support</a>.</p></dd>

	<dt><a href="http://www.opera.com/">Opera</a></dt>
	<dd><p>Userscript support must be enabled first and the file must be copied
			to scripts directory manually.</p>
		<p>Known issues:</p>
		<ul>
			<li>Opera fakes <a href="https://developer.mozilla.org/en/DOM/Selection">DOM selection</a> support;
				<a href="https://developer.mozilla.org/en/DOM/Selection/containsNode">containsNode</a> method always returns false.
				Because of this script cannot detect selected links.</li>
		</ul>
	</dd>

	<dt><a href="http://projects.gnome.org/epiphany/">Epiphany</a></dt>
	<dd><p>You must install Epiphany <a href="http://projects.gnome.org/epiphany/extensions">extensions</a>,
		enable Greasemonkey and save userscript file in
		<tt>$HOME/.gnome2/epiphany/extensions/data/greasemonkey/</tt>
		directory.</p></dd>

	<dt><a href="http://uzbl.org/">UZBL</a></dt>
	<dd><p>Save the script as <tt>$XDG_DATA_HOME/uzbl/rsget.js</tt> and add keybinding in your uzbl config:</p>
		<pre>@cbind  dr   = script @scripts_dir/rsget.js</pre>
		<p>Invoke this keybinding to enable script on given site.
		If you want to have it always enabled, bind it to LOAD_FINISH event:</p>
		<pre>@on_event   LOAD_FINISH script @scripts_dir/rsget.js</pre>
		<p>Known issues:</p>
		<ul>
			<li>NEW_WINDOW event is not yet fully implemented. It does not work with rsget.pl userscript.
			You have to enable uzbl-specific hacks either by selecting uzbl&nbsp;hacks checkbox, or by
			setting uzbl_hacks variable in generated script.</li>
		</ul>
	</dd>
</dl>

<form method="post" action="/tools/userscript/config">
<h2>Configuration</h2>
<dl>
	<dt>Where your rsget.pl can be found</dt>
	<dd><input type="text" name="host"
		value="<?= isset( $_REQUEST["host"] ) ? $_REQUEST["host"] : "http://localhost:7666/" ?>"
		/></dd>
	<dt>Open menu on all supported pages (including flash-based)</dt>
	<dd><label for="open_supported">always open</label>:
		<input type="checkbox" id="open_supported" name="open_supported"
		<?= isset( $_REQUEST["open_supported"] ) ? 'checked="checked"' : '' ?>
		/></dd>
	<dt>Are you using UZBL ? If so, enable uzbl-specific hacks</dt>
	<dd><label for="uzbl_hacks">uzbl hacks</label>:
		<input type="checkbox" id="uzbl_hacks" name="uzbl_hacks"
		<?= isset( $_REQUEST["uzbl_hacks"] ) ? 'checked="checked"' : '' ?>
		/></dd>
	<dt>All done ?</dt>
	<dd><input type="submit" value="Get it !" /></dd>
</dl>
</form>
