<?xml version="1.0" encoding="UTF-8" ?>
<!--
    xml2wiki.xsl
    Transform xml from deepbills into wiki text for wikisource
    Created by Francis Avila on 2013-04-04.
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

<variable name="author">
    <variable name="normalized" select="normalize-space()"/>
    <variable name="authorid" select="(//sponsor/@name-id)[1]"/>
    <variable name="wikipage">
        <call-template name="wikipedia-key">
            <with-param name="id" select="$authorid"/>
            <with-param name="lookupdoc" select="$people"/>
        </call-template>
    </variable>
    <value-of select="$wikipage"/>
</variable>

<variable name="besttitle" select="//short-title[text()] | //official-title[text() and not (//short-title[text()])]"/>
<variable name="billtype" select="/doc/docmeta/bill/@type"/>

<template match="/doc">
<variable name="action-date" select="*[2]/form/action/action-date/@date"/>{{header
 | title      = <value-of select="normalize-space($besttitle)"/> ( <value-of select='translate($billtype, "abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ")'/> <value-of select="docmeta/bill/@number"/> ; <value-of select="docmeta/bill/@congress"/><text>th Congress)</text>
 | author     = <value-of select="$author"/>
 | related_author = United States Congress
 | translator = 
 | section    = 
 | previous   = 
 | next       = 
 | year       = <value-of select="substring($action-date, 1, 4)"/>
 | month      = <value-of select="substring($action-date, 5, 2)"/>
 | day        = <value-of select="substring($action-date, 7, 2)"/>
 | notes      = ''{{USBill|<value-of select="docmeta/bill/@congress"/>|<value-of select="$billtype"/>|<value-of select="docmeta/bill/@number"/>}}''<text> as introduced</text>
 | categories =
 | portal     =
 | congress   = <value-of select="docmeta/bill/@congress"/>
 | session    = <value-of select="substring(*[2]/form/session, 1, 1)"/>
 | title      = <value-of select="normalize-space($besttitle)"/> ( <value-of select='translate($billtype, "abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ")'/> <value-of select="docmeta/bill/@number"/> ; <value-of select="docmeta/bill/@congress"/><text>th Congress)</text>
 | bill       = <value-of select="docmeta/bill/@number"/>
 | billtype   = <value-of select="docmeta/bill/@type"/>
 | purpose    = <value-of select="normalize-space(*[2]/form/official-title)"/>
 | wikipedia  =
}}
<apply-templates select="*[2]"/>
<text>
{{PD-USGov}}
[[Category:Proposed United States federal law]]
[[Category:Proposed United States federal law of the 113th Congress]]
</text>    
</template>


<template match="distribution-code"/>
<template match="dublinCore"/>

<template match="congress|session|legis-num|legis-type|current-chamber|action-desc|action-date">
{{Center|<apply-templates/>}}

</template>

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

<template match="sponsor | cosponsor | cato:entity-ref[@entity-type='person']">
    <text>&#xA;</text>
    <call-template name="wikilink">
        <with-param name="id" select="(@name-id | @entity-id)[1]"/>
        <with-param name="idx" select="$people"/>
    </call-template>
</template>

<template match="cato:entity-ref[@entity-type='federal-body']">
    <text> </text>    
    <call-template name="wikilink">
        <with-param name="id" select="(@entity-id | @entity-parent-id)[1]"/>
        <with-param name="idx" select="$federal-bodies"/>
    </call-template>
</template>

<template match="cato:entity-ref[@entity-type='act']">
    <text> </text>    
    <apply-templates/>
</template>

<template match="committee-name">
    <text> </text>    
    <call-template name="wikilink">
        <with-param name="id" select="(@committee-id | @committee)[1]"/>
        <with-param name="idx" select="$committees"/>
    </call-template>
</template>

<template match="cato:entity-ref[@entity-type='committee']">
    <text> </text>    
    <call-template name="wikilink">
        <with-param name="id" select="(@entity-id | @committee)[1]"/>
        <with-param name="idx" select="$committees"/>
    </call-template>
</template>

<template match="cato:entity-ref[@entity-type='public-law']
    | external-xref[@legal-doc='public-law']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="congress" select="$parts[2]"/>
    <variable name="number" select="$parts[3]"/>
    <text>[[Public Law </text>
    <value-of select="concat($congress, '-', $number)"/>
    <text>|</text>
    <apply-templates/>
    <text>]] </text>
</template>

<template match="cato:entity-ref[@entity-type='uscode'][starts-with(@value, 'usc/')]
    |external-xref[@legal-doc='usc']">
    <variable name="parts" select="str:tokenize(@value, '/')"/>
    <variable name="title" select="$parts[2]"/>
    <variable name="section" select="$parts[3]"/>
    <text>[http://www.law.cornell.edu/uscode/text/</text>
    <value-of select="concat($title,'/',$section)"/>
    <text> </text>
    <apply-templates/>
    <text>] </text>
</template>

<!-- 

<template match="cato:entity-ref[@entity-type='statute-at-large']">
</template>

<template match="external-xref[@legal-doc='statute-at-large']">
</template>

<template match="external-xref[@legal-doc='usc-chapter']">
</template>

<template match="external-xref[@legal-doc='usc-appendix']">
</template>
 -->

<template match="toc">
    <!-- TOC is created by hand 
    <text>__NOTOC__&#xA;</text>-->
    <apply-templates/>
</template>

<template match="toc-entry[@idref]">
    <if test="@level='title'">*</if>
    <if test="@level='section'">**</if>
    <text>[[#</text>
    <value-of select="@idref"/>
    <text>|</text>
    <apply-templates/>
    <text>]]&#xA;</text>
</template>

<template name="string-repeat">
    <param name="string"/>
    <param name="count"/>
    <if test="string-length($string) > 0 and $count > 0">
        <value-of select="$string"/>
        <call-template name="string-repeat">
            <with-param name="string" select="$string"/>
            <with-param name="count" select="$count - 1"/>
        </call-template>
    </if>
</template>

<template match="@id"></template>
<!-- 
    removed per Michelle. Yuck.
    <template match="@id">{{anchor|<value-of select="."/>}}</template> -->

<template name="level">
    <param name="context" select="."/>
    <value-of select="1 + count($context/ancestor-or-self::*[
        self::title | self::subtitle | self::chapter | self::part |
        self::subsection | self::paragraph | self::subparagraph |
        self::clause | self::subclause | self::item | self::subitem])"/>
</template>

<template match="title/enum[following-sibling::header]">
    <text>Title </text><value-of select="."/><text>— </text>
</template>

<template match="section/enum[following-sibling::header]">
    <text>Sec. </text><value-of select="."/><text> </text>
</template>

<template match="section[@section-type='section-one']/enum[following-sibling::header]">
    <text>Section </text><value-of select="."/><text> </text>
</template>


<template priority="-0.5" match="enum">
    <value-of select="."/>
    <text> </text>
</template>

<template match="header[not(@display-inline='no-display-inline') and not(parent::section or parent::title)]">
    <apply-templates select="./text()"/>
    <text>– </text>
</template>

<template match="term">
    <text> </text>
    <apply-templates select="./text()"/>
    <text> </text>
</template>

<!-- <template match="header">
   <call-template name="search-and-replace">
     <with-param name="input" select="text()" />
     <with-param name="search-string" select="'&#x9;'" />
     <with-param name="replace-string" select="''" />
   </call-template>  
    <text>– </text>
</template>
 -->

<template 
    name="block-unit"
    match="*[child::enum][self::section or self::title or child::header[not(@display-inline='yes-display-inline')]]">
    <variable name="wikiheader">
        <call-template name="string-repeat">
            <with-param name="string">=</with-param>
            <with-param name="count"><call-template name="level"/></with-param>
        </call-template>
    </variable>
    <text>&#xA;&#xA;</text>
    <value-of select="$wikiheader"/>
        <apply-templates select="@id"/>
        <apply-templates select="enum"/>
        <apply-templates select="header"/>
    <value-of select="$wikiheader"/>
    <text>&#xA;&#xA;</text>
    <apply-templates select="*[not(self::enum or self::header)]"/>
</template>

<template 
    name="inline-unit"
    match="*[not(self::title or self::section)]
        [child::enum][not(child::header) or child::header[@display-inline='yes-display-inline']]">
    <param name="parentlevel">
        <call-template name="level">
            <with-param name="context" select="ancestor::*[child::enum and child::header]"/>
        </call-template>
    </param>
    <variable name="currentlevel">
        <call-template name="level"/>
    </variable>
    <text>&#xA;</text>
    <call-template name="string-repeat">
        <with-param name="string">:</with-param>
        <with-param name="count" select="$currentlevel - $parentlevel"/>
    </call-template>
    <apply-templates select="enum"/>
    <apply-templates select="header"/>
    <apply-templates select="*[not(self::enum or self::header)]">
        <with-param name="parentlevel" select="$parentlevel"/>
    </apply-templates>
</template>

<template match="quoted-block">
    <text>&#xA;&#xA;&lt;blockquote></text>
    <apply-templates/>
    <text>&#xA;&lt;/blockquote>&#xA;</text>
</template>
</stylesheet>






