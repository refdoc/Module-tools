<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace"
 xmlns:teiosis="http://www.crosswire.org/2013/TEIOSIS/namespace"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://www.crosswire.org/2013/TEIOSIS/namespace http://www.crosswire.org/OSIS/teiP5osis.2.5.0.xsd">

  <!-- Transforms OSIS files created by usfm2osis.py for use in making SWORD TEI dictionary modules !-->

  <xsl:output indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <xsl:template match="/">
    <xsl:element name="TEI" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
      <xsl:copy-of select="document('')/*/@xsi:schemaLocation"/>
      <xsl:for-each-group select="//node()" group-starting-with="osis:seg[@type='keyword']">
        <xsl:choose>
          <xsl:when test="position()=1"/><!-- drop stuff before first keyword -->
          <xsl:otherwise>
            <xsl:element name="entryFree" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
              <xsl:attribute name="n"><xsl:value-of select="."/></xsl:attribute>
              <!-- Select only those nodes with no parent element in the current-group, because teiosis template does a recursive copy -->
              <xsl:for-each select="current-group()[count(index-of(current-group(), ./..))=0]"><xsl:call-template name="teiosis"/></xsl:for-each>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:element>
  </xsl:template>

  <!-- Filter and change all element namespaces to teiosis -->
  <xsl:template name="teiosis">
    <xsl:choose>
      <xsl:when test="self::comment()|self::osis:chapter|self::osis:title[@type='x-chapterLabel']|self::osis:seg[@type='keyword']"/><!-- Filter any unwanted elements here -->
      <xsl:when test="self::text()"><xsl:value-of select="."/></xsl:when>
      <xsl:otherwise>
        <xsl:element name="{local-name()}" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
          <xsl:copy-of select="@*"/>
          <!-- Do not recurse on child nodes following a keyword element, since these nodes are part of the next group -->
          <xsl:for-each select="node()[count(preceding-sibling::*/descendant-or-self::osis:seg[@type='keyword']) = 0]">
            <xsl:call-template name="teiosis"/>
          </xsl:for-each>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
