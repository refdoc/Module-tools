<?xml version="1.0" encoding="UTF-8" ?>
<stylesheet version="2.0"
 xmlns="http://www.w3.org/1999/XSL/Transform"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 
 <output standalone="yes" indent="yes"/>
 <strip-space elements="*"/>

  <!-- Transforms OSIS files created by usfm2osis.py for use with 
  GoBible Creator -->
  
  <!-- Make two passes over the entire node set -->
  <template match="/">
    <!-- PASS 1: simplify the OSIS hierarchy, and filter out notes, 
    non canonical titles etc.. -->
    <variable name="pass1"><apply-templates mode="pass1"/></variable>
    
    <!-- PASS 2: insure chapter and verse tags are container elements -->
    <apply-templates mode="pass2" select="$pass1"/>
  </template>
  
  <template mode="pass1" match="node()|@*">
    <apply-templates mode="#current" select="node()|@*"/>
  </template>
  
  <!-- Keep these elements and most of their text descendants (on pass2,  
  text nodes outside of verses will also be dropped) -->
  <template mode="pass1" match="text() |
                                osis:osis |
                                osis:osisText |
                                osis:div[@type='book'] |
                                *[@type='canonical'] |
                                osis:chapter |
                                osis:verse" priority="5">
    <copy><copy-of select="@*"/><apply-templates mode="#current"/></copy>
  </template>
  
  <!-- Remove these elements entirely (including their text descendants)-->
  <template mode="pass1" match="osis:header |
      osis:div[@type='book'][not(descendant::osis:verse)] |
      osis:title[not(@type='canonical')] |
      osis:note" priority="10"/>
  
  <template mode="pass2" match="node()|@*">
    <copy><apply-templates mode="#current" select="node()|@*"/></copy>
  </template>
  
  <!-- GoBible Creator requires a bookGroup div --> 
  <template mode="pass2" match="osis:osisText">
    <copy>
      <apply-templates mode="#current" select="@*"/>
      <element name="div" 
          namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
        <attribute name="type">bookGroup</attribute>
        <for-each select="descendant::osis:div[@type='book']">
          <call-template name="book"/>
        </for-each>
      </element>
    </copy>
  </template>
  
  <!-- Support verse container elements (although normally verse tags
  are milestones) -->
  <template mode="pass2" match="osis:verse">
    <apply-templates mode="#current"/>
  </template>
 
 <!-- Insure chapters are container elements -->
  <template name="book">
    <copy>
      <apply-templates mode="pass2" select="@*"/>
      <choose>
        <!-- this handles chapter as container element -->
        <when test="child::osis:chapter/osis:verse">
          <for-each select="child::osis:chapter">
            <copy>
              <apply-templates mode="pass2" select="@*"/>
              <for-each-group select="node()" 
                  group-starting-with="osis:verse[@sID]">
                <call-template name="verse"/>
              </for-each-group>
            </copy>
          </for-each>
        </when>
        <!-- this handles chapter as milestone -->
        <otherwise>
          <for-each-group select="node()" 
              group-starting-with="osis:chapter[@sID]">
            <choose>
              <!-- remove introductions -->
              <when test="position() = 1 and 
                          name(current()) != 'chapter'"/>
              <otherwise>
                <element name="chapter" 
                    namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
                  <attribute name="osisID" select="current()/@sID"/>
                  <for-each-group select="current-group()[not(self::osis:chapter)]" 
                      group-starting-with="osis:verse[@osisID]">
                    <call-template name="verse"/>
                  </for-each-group>
                </element>
              </otherwise>
            </choose>
          </for-each-group>
        </otherwise>
      </choose>
    </copy>
  </template>
  
  <!-- Insure verses are container elements, and add dummy verses 
  after multi-verse osisIDs, as required by GoBible Creator -->
  <template name="verse">
    <choose>
      <when test="position() = 1 and name(current()) != 'verse'"/>
      <otherwise>
        <element name="verse" 
            namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">
          <apply-templates mode="pass2" select="current-group()"/>
        </element>
        <for-each select="remove(tokenize(current()/@osisID, '\s+'), 1)">
          <element name="verse" 
              namespace="http://www.bibletechnologies.net/2003/OSIS/namespace">.</element>
        </for-each>
      </otherwise>
    </choose>
  </template>

</stylesheet>
