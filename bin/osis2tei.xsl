<?xml version="1.0" encoding="UTF-8" ?>
<stylesheet version="2.0"
 xmlns="http://www.w3.org/1999/XSL/Transform"
 xmlns:my="Module-tools/bin/osis2tei.xsl"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xpath-default-namespace="http://www.bibletechnologies.net/2003/OSIS/namespace"
 exclude-result-prefixes="#all">

  <!-- Transforms OSIS files created by usfm2osis.py for use in making SWORD TEI dictionary modules !-->
  <template match="/">
    <element name="TEI" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
      <attribute name="xsi:schemaLocation">http://www.crosswire.org/2013/TEIOSIS/namespace http://www.crosswire.org/OSIS/teiP5osis.2.5.0.xsd</attribute>
      <element name="text" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
        <element name="body" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
          <for-each select="//div[@type='glossary']">
            <for-each-group select="node()" group-by="my:groups(.)">
              <variable name="myKey" as="element(seg)?" 
                  select="current-group()/descendant-or-self::seg[@type='keyword']
                                         [my:groups(.) = current-grouping-key()]"/>
              <if test="$myKey">
                <element name="entryFree" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
                  <attribute name="n" select="$myKey/normalize-space(string())"/>
                  <apply-templates select="current-group()"/>
                </element>
                <text>&#xa;</text>
              </if>
            </for-each-group>
          </for-each>
        </element>
      </element>
    </element>
  </template>
  
  <template match="node()" priority="2">
    <if test="my:groups(.) = current-grouping-key()"><next-match/></if>
  </template>
  
  <template match="@*"><copy/></template>
  <template match="text()"><copy-of select="replace(., '[\s\n]+', ' ')"/></template>
  
  <!-- convert this group's elements to TEI namespace -->
  <template match="element()">
    <element name="{local-name()}" namespace="http://www.crosswire.org/2013/TEIOSIS/namespace">
      <apply-templates select="node()|@*"/>
    </element>
  </template>
  
  <!-- flatten any p|div containing only whitespace -->
  <template match="p | div">
    <choose>
      <when test="descendant::text()[normalize-space()]
                                    [not(parent::seg[@type='keyword'])]
                                    [my:groups(.) = current-grouping-key()]">
        <next-match/>
      </when>
      <otherwise><apply-templates/></otherwise>
    </choose>
  </template>
  
  <!-- filter out unwanted elements -->
  <template match="chapter | title[@type='x-chapterLabel'] | seg[@type='keyword']" priority="3"/>
  
  <function name="my:groups" as="xs:integer+">
    <param name="node" as="node()"/>
    <sequence select="for $i in $node/descendant-or-self::node() return
                        count($i[ancestor-or-self::seg[@type='keyword']]) +
                        count($i/preceding::seg[@type='keyword'])"/>
  </function>

</stylesheet>
