<xsl:stylesheet 
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:perl="urn:perl"
	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
	>
 
	<xsl:output method="xml" indent="no" encoding="UTF-8"/>
 
	<xsl:template match="/log">
		<html>
			<xsl:text>
	</xsl:text>
			<p>Commits: <xsl:value-of select="count( logentry )"/></p>
			<xsl:text>
	</xsl:text>
			<dl>
				<xsl:apply-templates select="logentry" />
			<xsl:text>
	</xsl:text>
			</dl>
			<xsl:text>
</xsl:text>
		</html>
	</xsl:template>
 
	<xsl:template match="logentry">
		<xsl:text>
		</xsl:text>
		<dt id="r{@revision}">
			<a href="http://svn.pld-linux.org/cgi-bin/viewsvn?rev={@revision}&amp;view=rev">
				<xsl:text>r</xsl:text>
				<xsl:value-of select="@revision"/>
			</a>
			<xsl:text>, </xsl:text>
			<a href="http://cia.vc/stats/author/{author}">
				<xsl:value-of select="author"/>
			</a>
			<xsl:text>, </xsl:text>
			<em>
				<xsl:value-of select="substring(date, 1, 10)"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="substring(date, 12, 8)"/>
				<xsl:text> UTC</xsl:text>
			</em>
		</dt>
		<xsl:text>
		</xsl:text>
		<dd>
			<xsl:apply-templates select="paths" />
			<pre>
				<xsl:value-of select="perl:fixlog( msg )" />
			</pre>
		</dd>
	</xsl:template>

	<xsl:template match="paths">
		<ul class="filelist">
			<xsl:apply-templates select="path">
				<xsl:sort select="text()" />
			</xsl:apply-templates>
		</ul>
	</xsl:template>

	<xsl:template match="path">
		<li class="file_{@action}">
			<a href="http://svn.pld-linux.org/cgi-bin/viewsvn{text()}">
				<xsl:if test="substring(text(), 1, 14) != '/toys/rsget.pl'">
					<xsl:text>../..</xsl:text>
					<xsl:value-of select="substring(text(), 1, 15)" />
				</xsl:if>
				<xsl:value-of select="substring(text(), 16)" />
				<xsl:if test="@kind='dir'"><xsl:text>/</xsl:text></xsl:if>
			</a>
		</li>
	</xsl:template>
 
</xsl:stylesheet>
