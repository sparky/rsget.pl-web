#!/bin/sh

rm -rf svn/rsget.pl-*

svn co http://svn.pld-linux.org/svn/toys/rsget.pl svn | tee svn_co.log
REV=$(tail -n1 svn_co.log | sed 's/.* //;s/\.$//')
rm svn_co.log

[ ! -r src/download/rsget.pl-svn-$REV.tar.bz2 ] || exit 0

set -x
rm -f src/download/rsget.pl-svn-*.tar.bz2
tar -jc --exclude-vcs --transform="s/^svn/rsget.pl-svn-$REV/" -f src/download/rsget.pl-svn-$REV.tar.bz2 svn

cat > src/download/snapshot.php <<EOF
<?php
header( 'Location: /download/rsget.pl-svn-$REV.tar.bz2' );
?>
EOF

