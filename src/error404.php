<?php
header('Content-type: text/xml; charset=utf-8');
echo '<?xml version="1.0" encoding="utf-8"?>';
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<!--
     http://rsget.pl/ error page
     2010-2011 (c) Przemysław Iskra <sparky@pld-linux.org>
-->
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
	<title>rsget.pl</title>
	<link rel="stylesheet" type="text/css" href="/_style/screen.css" media="screen" />
	<link rel="stylesheet" type="text/css" href="/_style/print.css" media="print" />
	<link rel="shortcut icon" href="/_style/favicon.png" />
</head>
<body id="body">

<div class="column center">
	<div class="head">
		<h1>Error 404</h1>
	</div>
	<div class="body">
		<a href="/"><img src="/_style/hook.png" class="logo" alt="rsget.pl" /></a>
		<p style="font-size: 20pt">File not found</p>
		<p>
			The requested file <strong>
			<?= isset( $_SERVER["REDIRECT_URL"] ) ? htmlspecialchars( $_SERVER["REDIRECT_URL"] ) : "" ?>
			</strong> was not found on this server.
		</p>
		<hr />
		<p>
			Try something else.
		</p>
		<address>2010-2011 (c) Przemysław Iskra &lt;sparky@pld-linux.org&gt;</address>
	</div>
	<hr class="foot"/>
</div>


</body>
</html>
