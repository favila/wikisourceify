<?xml version="1.0" encoding="UTF-8" ?>
<!--
    xml2wiki.xsl
    Transform xml from deepbills into wiki text for wikisource
    Created by Francis Avila on 2013-04-04.
-->

<stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:cato="http://namespaces.cato.org/catoxml">

<strip-space elements="*"/>
<!-- <preserve-space elements="text continuation-text quoted-block-continuation-text quote"/> -->
<output encoding="UTF-8" method="text" omit-xml-declaration="yes" indent="no"/>

<variable name="people" select="document('../lookups/person.xml')"/>
<variable name="committees" select="document('../lookups/committee.xml')"/>
<variable name="federal-bodies" select="document('../lookups/federal-body.xml')"/>


<key name="wikipedia" match="/items/item/@wikipedia" use="../@id"/>

<template match="text()">
    <variable name="normalized" select="normalize-space()"/>
    <!-- TODO: this should have <nowiki> to prevent wiki-interpretation of text nodes -->
    <!-- However doing this adds a lot of bloat to the output. Is there a smarter way
         to add <nowiki> conditionally? -->
    <copy select="$normalized"/>
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


<template match="/doc">
<variable name="action-date" select="*[2]/form/action/action-date/@date"/>
{{Act of Congress
| congress       = <value-of select="docmeta/bill/@congress"/>
| session        = <value-of select="substring(*[2]/form/session, 1, 1)"/>
<!-- | pl             =  -->
| title          = <value-of select="normalize-space(*[2]/form/official-title)"/>
<!-- | override_previous =  -->
<!-- | statvolume     =  -->
<!-- | statpage       =  -->
| year           = <value-of select="substring($action-date, 1, 4)"/>
| month          = <value-of select="substring($action-date, 5, 2)"/>
| day            = <value-of select="substring($action-date, 7, 2)"/>
| bill           = <value-of select="docmeta/bill/@number"/>
| billtype       = <value-of select="docmeta/bill/@type"/>
<!-- | notes          =  -->
<!-- | resolution     =  -->
| purpose        = <value-of select="normalize-space(*[2]/form/official-title)"/>
}}
<apply-templates select="*[2]"/>
</template>


<template match="distribution-code"/>

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
            <text>[[Wikipedia:</text>
            <value-of select="$wikipage"/>
            <text>|</text>
            <apply-templates/>
            <text>]]</text>
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
    <call-template name="wikilink">
        <with-param name="id" select="(@entity-id | @entity-parent-id)[1]"/>
        <with-param name="idx" select="$federal-bodies"/>
    </call-template>
</template>

<template match="committee-name">
    <call-template name="wikilink">
        <with-param name="id" select="(@committee-id | @committee)[1]"/>
        <with-param name="idx" select="$committees"/>
    </call-template>
</template>

<!-- 
<template match="cato:entity-ref[@entity-type='public-law']">
</template>

<template match="external-xref[@legal-doc='public-law']">
</template>

<template match="cato:entity-ref[@entity-type='statute-at-large']">
</template>

<template match="external-xref[@legal-doc='statute-at-large']">
</template>

<template match="cato:entity-ref[@entity-type='uscode']">
</template>

<template match="external-xref[@legal-doc='usc']">
</template>

<template match="external-xref[@legal-doc='usc-chapter']">
</template>

<template match="external-xref[@legal-doc='usc-appendix']">
</template>
 -->

<template match="toc">
    <!-- TOC is created by hand -->
    <text>__NOTOC__&#xA;</text>
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

<template match="@id">{{anchor|<value-of select="."/>}}</template>

<template name="level">
    <param name="context" select="."/>
    <value-of select="1 + count($context/ancestor-or-self::*[
        self::title | self::subtitle | self::chapter | self::part |
        self::subsection | self::paragraph | self::subparagraph |
        self::clause | self::subclause | self::item | self::subitem])"/>
</template>

<template match="*[enum and header]">
    <variable name="wikiheader">
        <call-template name="string-repeat">
            <with-param name="string">=</with-param>
            <with-param name="count"><call-template name="level"/></with-param>
        </call-template>
    </variable>
    <!-- <variable name="use-section" select="self::title[@id] or self::section[@id]"/> -->
    <variable name="use-section" select="false()"/>
    <text>&#xA;</text>
    <if test="$use-section">
        <text>{{section|</text><value-of select="@id"/><text>|&#xA;</text>
    </if>
    <value-of select="$wikiheader"/>
        <value-of select="normalize-space(concat(enum, ' ', header))"/>
    <value-of select="$wikiheader"/>
    <text>&#xA;&#xA;</text>
    <apply-templates select="*[not(self::enum or self::header)]"/>
    <if test="$use-section">
        <text>}}&#xA;</text>
    </if>
</template>

<template match="enum[not(following-sibling::header)]">
    <variable name="parentlevel">
        <call-template name="level">
            <with-param name="context" select="../ancestor::*[child::enum and child::header]"/>
        </call-template>
    </variable>
    <variable name="currentlevel">
        <call-template name="level">
            <with-param name="context" select=".."/>
        </call-template>
    </variable>
    <call-template name="string-repeat">
        <with-param name="string">:</with-param>
        <with-param name="count" select="$currentlevel - $parentlevel"/>
    </call-template>
    <text> </text>
</template>

<template match="quoted-block">
    <text>&#xA;&#xA;&lt;blockquote></text>
    <apply-templates/>
    <text>&lt;/blockquote>&#xA;</text>
</template>
</stylesheet>






