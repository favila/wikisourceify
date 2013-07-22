<?xml version="1.0" encoding="UTF-8" ?>
<!--
    xml2infobox.xsl
    Transform xml from deepbills into wikipedia header
    based on work created by Francis Avila on 2013-04-04.
    Don Whiteside 27 June 2013
-->
<stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:cato="http://namespaces.cato.org/catoxml"
    xmlns:str="http://exslt.org/strings"
    extension-element-prefixes="str">

<strip-space elements="*"/>
<!-- <preserve-space elements="text continuation-text quoted-block-continuation-text quote"/> -->
<output encoding="UTF-8" method="text" omit-xml-declaration="yes" indent="no"/>

<variable name="people" select="document('../lookups/person.xml')"/>
<variable name="committees" select="document('../lookups/committee.xml')"/>
<variable name="federal-bodies" select="document('../lookups/federal-body.xml')"/>

<key name="wikipedia" match="/items/item/@wikipedia" use="../@id"/>
<key name="nicename" match="/items/item/@name" use="../@id"/>
<key name="committees" match="/doc/bill/form/action/committee-name" use="committee-id" />
<key name="federal-bodies" match="cato:entity-ref[@entity-type='federal-body']" use="@entity-id"/>

<template name="search-and-replace">
    <param name="input"/>
    <param name="search-string"/>
    <param name="replace-string"/>
    <choose>
    <when test="$search-string and contains($input,$search-string)">
       <value-of
           select="substring-before($input,$search-string)"/>
       <value-of select="$replace-string"/>
       <call-template name="search-and-replace">
         <with-param name="input" select="substring-after($input,$search-string)"/>
         <with-param name="search-string" select="$search-string"/>
         <with-param name="replace-string" select="$replace-string"/>
       </call-template>
    </when>
    <otherwise>
      <value-of select="$input"/>
    </otherwise>
    </choose>
</template>

<template match="text()">
    <!-- the normalization presentes an issue we'll need to address when it's getting down to certain levels -->
    <variable name="normalized" select="normalize-space()"/>
    <variable name="wikiescape" select="contains(., '[') or contains(., '{{') or contains('.', &quot;&apos;&apos;&quot;)"/>
    <if test="$wikiescape">&lt;nowiki></if>
<!-- We're going to de-tab the text when we get down to the nitty-gritty, else it goofs up the wikiheaders etc -->
   <call-template name="search-and-replace">
     <with-param name="input" select="$normalized" />
     <with-param name="search-string" select="'&#x9;'" />
     <with-param name="replace-string" select="''" />
   </call-template>
<!--     <copy select="$normalized"/> -->
    <if test="$wikiescape">&lt;/nowiki></if>
    <if test="string-length($normalized)=0 and string-length(.)>0">
        <text> </text>
    </if>
</template>

<!-- <template match="*[@display-inline='no-display-inline'] | text[not(@display-inline)]">
    <text>&#xA;</text>
    <apply-templates/>
    <text>&#xA;</text>
</template>
 -->

<template match="quote">
    <text>“</text>
    <apply-templates/>
    <text>”</text>
</template>

<template name="wikipedia-key">
    <param name="id"/>
    <param name="lookupdoc"/>
    <for-each select="$lookupdoc">
        <value-of select="key('wikipedia', $id)"/>
    </for-each>
</template>

<template name="wikipedia-name">
    <param name="id"/>
    <param name="lookupdoc"/>
    <for-each select="$lookupdoc">
        <value-of select="key('nicename', $id)"/>
    </for-each>
</template>

<template name="wikilinkperson">
    <param name="id"/>
    <variable name="wikipage">
        <call-template name="wikipedia-key">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$people"/>
        </call-template>
    </variable>
    <variable name="wikiname">
        <call-template name="wikipedia-name">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$people"/>
        </call-template>
    </variable>    
    <text>[[w:</text>
    <value-of select="$wikipage"/>
    <text>|</text>
    <value-of select="$wikiname"/>    
    <text>]] </text>
</template>

<template name="wikilinkcommittee">
    <param name="id"/>
    <variable name="wikipage">
        <call-template name="wikipedia-key">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$committees"/>
        </call-template>
    </variable>
    <variable name="wikiname">
        <call-template name="wikipedia-name">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$committees"/>
        </call-template>
    </variable>    
    <text>[[w:</text>
    <value-of select="$wikipage"/>
    <text>|</text>
    <value-of select="$wikiname"/>    
    <text>]] </text>
</template>

<template match="committee-name">
    <call-template name="wikilinkcommittee">
        <with-param name="id" select="(@committee-id | @committee)[1]"/>
    </call-template>
</template>

<variable name="author">
    <variable name="normalized" select="normalize-space()"/>
    <variable name="authorid" select="(//sponsor/@name-id)[1]"/>
    <variable name="wikiit">
        <call-template name="wikilinkperson">
            <with-param name="id" select="$authorid"/>
        </call-template>
    </variable> 
    <value-of select="$wikiit"/>
</variable>

<variable name="chamber">
    <variable name="chamber-code" select="//docmeta/@id"/>
    <variable name="chamber-char" select="substring($chamber-code, string-length($chamber-code))"/>
    <if test="$chamber-char='h'"><text>House</text></if>
    <if test="$chamber-char='s'"><text>Senate</text></if>
</variable>

<variable name="shorttitle" select="//short-title[text()]"/>
<variable name="fulltitle" select="//official-title[text()]"/>
<variable name="besttitle" select="//short-title[text()] | //official-title[text() and not (//short-title[text()])]"/>
<variable name="billtype" select="/doc/docmeta/bill/@type"/>
<variable name="action-date" select="*[2]/form/action/action-date/@date"/>

<template name="wikilink">
    <param name="id"/>
    <param name="idx"/>
    <variable name="wikipage">
        <call-template name="wikipedia-key">
            <with-param name="id" select="$id"/>
            <with-param name="lookupdoc" select="$idx"/>
        </call-template>
    </variable>
    <choose>
        <when test="$wikipage">
            <text>[[w:</text>
            <value-of select="$wikipage"/>
            <text>|</text>
            <apply-templates/>
            <text>]] </text>
        </when>
        <otherwise>
            <apply-templates/>
        </otherwise>
    </choose>
</template>


<!--
Using the key and Muenchian grouping to remove dupes
-->
<template match="cato:entity-ref[@entity-type='federal-body']">
    <for-each select="entity-ref[count(. | key('federal-bodies', @entity-id)[1]) = 1]">
        <for-each select="key('federal-bodies', @entity-id)">
            <call-template name="wikilink">
                <with-param name="id" select="(@entity-id | @entity-parent-id)[1]"/>
                <with-param name="idx" select="$federal-bodies"/>
            </call-template>
        </for-each>
    </for-each>
</template>

<template match="cato:entity-ref[@entity-type='public-law']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="congress" select="$parts[2]"/>
    <variable name="pl-number" select="$parts[3]"/>
    <text>{{USPL</text>
    <value-of select="concat($congress, '|', $pl-number)"/>
    <text>}}</text>
</template>

<template match="cato:entity-ref[@entity-type='statute-at-large']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="congress" select="$parts[2]"/>
    <variable name="sal-number" select="$parts[3]"/>
    <text>{{SAL</text>
    <value-of select="concat($congress, '|', $sal-number)"/>
    <text>}}</text>
</template>

<!-- 
we need to cope with fact that amount might be indefinite
-->
<variable name="appropriated-amount" select="sum(//cato:funds-and-year/@amount)"/>
<!-- 
wuff what a hassle. this is option but may have values like:
2015
2015,2017,2019
2012..2020
2014,..
..,2016

<variable name="appropriated-start" select="min(//cato:funds-and-year/@year)"/>
<variable name="appropriated-end" select="max(//cato:funds-and-year/@year)"/>
-->
<!-- example: <cato:funds-and-year amount="2800000000" year="2014..2018">-->

<template name="appropriated-sum">
      <!-- Initialize nodes to empty node set -->
      <param name="nodes" select="/.."/>
      <param name="result" select="0"/>
      <choose>
        <when test="not($nodes)">
          <value-of select="$result"/>
        </when>
        <otherwise>
            <!-- call or apply template that will determine value of node
              unless the node is literally the value to be summed -->
          <variable name="value">
            <call-template name="some-function-of-a-node">
              <with-param name="node" select="$nodes[1]"/>
            </call-template>
          </variable>
            <!-- recurse to sum rest -->
<call-template name="appropriated-sum">
<with-param name="nodes" select="$nodes[position() != 1]"/> <with-param name="result" select="$result + $value"/>
          </call-template>
        </otherwise>
      </choose>
    </template>

<!--
<template name="agencies-affected" select="/entity-ref[@entity-type='federal-body']">
    <for-each select="entity-ref[@entity-type='federal-body']">
    <call-template name="wikilink">
        <with-param name="id" select="(@entity-id | @entity-parent-id)[1]"/>
        <with-param name="idx" select="$federal-bodies"/>
    </call-template>
    </for-each>
</template>
-->

<variable name="agencies-affected">
    <apply-templates select="//cato:entity-ref[@entity-type='federal-body']"/>
</variable>

<variable name="public-law">
    <apply-templates select="//cato:entity-ref[@entity-type='public-law']"/>
</variable>

<variable name="uscode">
    <apply-templates select="//cato:entity-ref[@entity-type='uscode']"/>
</variable>

<variable name="statute-at-large">
    <apply-templates select="//cato:entity-ref[@entity-type='statute-at-large']"/>
</variable>


<template match="/doc">
<!--
<variable name="committee-referred">
    <call-template name="wikipedia-key">
        <with-param name="id" select="HGO00"/>
        <with-param name="idx" select="$committees"/>
    </call-template>
</variable>
-->
{{Infobox U.S. legislation
| name            = <value-of select="normalize-space($shorttitle)"/>
| fullname        = <value-of select="normalize-space($fulltitle)"/>
| acronym         = 
| nickname        = <!--Unofficial name used by the press or general public-->
| introduced in the = <value-of select="docmeta/bill/@congress"/>th<!--Name of Congress. (e.g. 1st, 10th, 100th). Auto-links to corresponding page. Adding other characters breaks the link-->
| introduceddate   = <value-of select="$action-date"/><!--date of introduction-->
| sponsored by    = <value-of select="$author"/>
| number of co-sponsors = <value-of select="count(//cosponsor)"/>
| public law url  = 
| cite public law = <value-of select="$public-law"/><!--{{USPL|XXX|YY}} where X is the congress number and Y is the law number-->
| cite statutes at large = <value-of select="$statute-at-large"/><!--{{usstat}} can be used-->
| acts amended    = <!--list, if applicable; make wikilinks where possible-->
| acts repealed   = <!--list, if applicable; make wikilinks where possible-->
| title amended   = <!--US code titles changed-->
| sections created = <!--{{USC}} can be used-->
| sections amended = <!--list, if applicable; make wikilinks where possible-->
| agenciesaffected = <value-of select="$agencies-affected"/> <!--list of federal agencies that would be affected by the legislation, wikilinks where possible-->
| authorizationsofappropriations = <!--a dollar amount, with dollar sign, possibly including a time period-->
| appropriations = <!--a dollar amount, with dollar sign, possibly including a time period-->
| leghisturl      = 
| introducedin    = <value-of select="$chamber"/>
| introducedbill  = ''{{USBill|<value-of select="docmeta/bill/@congress"/>|<value-of select="$billtype"/>|<value-of select="docmeta/bill/@number"/>}}''
| introducedby    = <value-of select="$author"/>
| introduceddate  = <value-of select="*[2]/form/action/action-date[text()]"/>
| committees      = <apply-templates select="bill/form/action/action-desc/committee-name"/>
| passedbody1     = <!--House or Senate-->
| passeddate1     = <!--date of passage-->
| passedvote1     = <!--give vote numbers, external link to roll call list where possible-->
| passedbody2     = <!--House or Senate-->
| passedas2       = <!-- used if the second body changes the name of the legislation -->
| passeddate2     = <!--date of passage-->
| passedvote2     = <!--give vote numbers, external link to roll call list where possible-->
| conferencedate  = 
| passedbody3     = 
| passeddate3     = 
| passedvote3     = 
| agreedbody3     = <!-- used when the other body agrees without going into committee -->
| agreeddate3     = <!-- used when the other body agrees without going into committee -->
| agreedvote3     = <!-- used when the other body agrees without going into committee -->
| agreedbody4     = <!-- used if agreedbody3 further amends legislation -->
| agreeddate4     = <!-- used if agreedbody3 further amends legislation -->
| agreedvote4     = <!-- used if agreedbody3 further amends legislation -->
| passedbody4     = 
| passeddate4     = 
| passedvote4     = 
| signedpresident = <!--name of the president, as wikilink-->
| signeddate      = 
| unsignedpresident = <!-- used when passed without presidential signing -->
| unsigneddate    = <!-- used when passed without presidential signing -->
| vetoedpresident = <!-- used when passed by overriding presidential veto -->
| vetoeddate      = <!-- used when passed by overriding presidential veto -->
| overriddenbody1 = <!-- used when passed by overriding presidential veto -->
| overriddendate1 = <!-- used when passed by overriding presidential veto -->
| overriddenvote1 = <!-- used when passed by overriding presidential veto -->
| overriddenbody2 = <!-- used when passed by overriding presidential veto -->
| overriddendate2 = <!-- used when passed by overriding presidential veto -->
| overriddenvote2 = <!-- used when passed by overriding presidential veto -->
| amendments      = 
| SCOTUS cases    = 
}}
</template>
</stylesheet>