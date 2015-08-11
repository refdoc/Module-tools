<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 
 <xsl:output standalone="yes" indent="yes"/>
 <xsl:strip-space elements="*"/>

  <!-- Transforms OSIS files created by usfm2osis.py and paratext2osis.pl for use with GoBible Creator -->
  
  <!-- Make two passes over entire node set -->
  <xsl:template match="/">
    <xsl:variable name="pass1">
      <xsl:apply-templates/>
    </xsl:variable>
    <xsl:apply-templates select="$pass1" mode="pass2"/>
  </xsl:template>
  
  <!-- PASS 1: FILTER AND SIMPLIFY ELEMENT HIERARCHY -->
  <xsl:template match="node()|@*" name="identity">
    <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- remove comments !-->
  <xsl:template match="comment()" priority="1"/>
  
  <!-- remove all tags by default -->
  <xsl:template match="*" priority="1">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- remove these elements entirely -->
  <xsl:template match="osis:w|osis:note|osis:title|osis:header" priority="2"/>
  
  <!-- but keep only these elements in their entirety -->
  <xsl:template match="osis:osis|osis:osisText|osis:div[@type='book']|*[@type='canonical']|osis:chapter|osis:verse" priority="3">
    <xsl:call-template name="identity"/>
  </xsl:template>
  
  <!-- PASS 2: MAKE CONTAINERS FROM MILESTONE CHAPTER (IF NEEDED) AND VERSE TAGS -->
  <xsl:template match="node()|@*" mode="pass2">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*" mode="pass2"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- GoBible Creator requires this bookGroup div --> 
  <xsl:template match="osis:osisText" mode="pass2">
    <xsl:copy>
      <xsl:element name="div" xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
        <xsl:attribute name="type">bookGroup</xsl:attribute>
        <xsl:apply-templates select="node()|@*" mode="pass2"/>
      </xsl:element>
    </xsl:copy>
  </xsl:template>
 
 <!-- Insure chapters are container elements -->
  <xsl:template match="osis:div[@type='book']" mode="pass2">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="pass2"/>
      <xsl:choose>
        <!-- this handles element chapters -->
        <xsl:when test="./osis:chapter/osis:verse">
          <xsl:for-each select="./osis:chapter">
            <xsl:copy>
              <xsl:apply-templates select="@*" mode="pass2"/>
              <xsl:for-each-group select="node()" group-starting-with="osis:verse[@sID]">
                <xsl:call-template name="verses"/>
              </xsl:for-each-group>
            </xsl:copy>
          </xsl:for-each>
        </xsl:when>
        <!-- this handles milestone chapters -->
        <xsl:otherwise>
          <xsl:for-each-group select="node()" group-starting-with="osis:chapter[@sID]">
            <xsl:choose>
              <xsl:when test="position()=1 and name(current())!='chapter'"/><!-- remove introductions -->
              <xsl:otherwise>
                <xsl:element name="chapter" xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
                  <xsl:attribute name="osisID" select="current()/@sID"/>
                  <xsl:for-each-group select="current-group()[not(self::osis:chapter)]" group-starting-with="osis:verse[@sID]">
                    <xsl:call-template name="verses"/>
                  </xsl:for-each-group>
                </xsl:element>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <!-- Convert milestone verses into containers, and add dummy verses after multi-verse elements, as required by GoBible Creator -->
  <xsl:template name="verses">
    <xsl:choose>
      <xsl:when test="position()=1 and name(current())!='verse'"/>
      <xsl:otherwise>
        <xsl:element name="verse" xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
          <xsl:apply-templates select="current-group()[not(self::osis:verse)]" mode="pass2"/>
        </xsl:element>
        <xsl:for-each select="remove(tokenize(current()/@osisID,'\s+'),1)">
          <xsl:element name="verse" xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">.</xsl:element>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
