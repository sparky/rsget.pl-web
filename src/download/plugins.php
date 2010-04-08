<?php
header( 'Content-type: text/plain; charset=utf-8' );

if (substr_count($_SERVER['HTTP_ACCEPT_ENCODING'], 'gzip'))
	ob_start("ob_gzhandler");
else
	ob_start();

function getters() {
	$dbh = null;
	try {
		$dbh = new PDO("sqlite:plugins.sqlite3.db", "", "" );
	} catch(PDOException $e) {
		echo $e->getMessage();
	}
	if ( ! $dbh )
		return;

	$sth = null;
	$sth = $dbh->prepare( "SELECT name, md5, body FROM plugins" );
	$sth->execute();

	$result = $sth->fetchAll();
	foreach ( $result as $row ) {
		$name = $row[0];
		$md5 = $row[1];
		if ( ! isset( $_POST[ $name ] ) || $_POST[ $name ] != $md5 ) {
			$length = strlen( $row[2] );
			echo "<plugin:$md5 name=\"$name\">";
			echo $row[2];
			echo "</plugin:$md5>\n";
		}
	}

	$dbh = null;
}

echo "<!-- plugins -->\n";
getters();
?>
