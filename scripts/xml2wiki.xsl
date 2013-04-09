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
<preserve-space elements="text continuation-text quoted-block-continuation-text quote"/>
<output encoding="UTF-8" method="text" omit-xml-declaration="yes" indent="no"/>

<variable name="people" select="document('../lookups/person.xml')"/>
<variable name="committees" select="document('../lookups/committee.xml')"/>
<variable name="federal-bodies" select="document('../lookups/federal-body.xml')"/>


<key name="wikipedia" match="/items/item/@wikipedia" use="../@id"/>

<template match="*">
    <apply-templates/>
    <text>&#xA;</text>
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
| pl             = 1
| title          = 
| override_previous = 
| statvolume     = 
| statpage       = 
| year           = <value-of select="substring($action-date, 1, 4)"/>
| month          = <value-of select="substring($action-date, 5, 2)"/>
| day            = <value-of select="substring($action-date, 7, 2)"/>
| bill           = <value-of select="docmeta/bill/@number"/>
| billtype       = <value-of select="docmeta/bill/@type"/>
| notes          = 
| resolution     = 
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
            <text>[[</text>
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

<template name="level">
    <choose>
        <when test="title">1</when>
        <when test="section">2</when>
    </choose>
</template>

<template match="*[self::title or self::section][enum or header]">
    <variable name="wikiheader">
        <call-template name="string-repeat">
            <with-param name="string">=</with-param>
            <with-param name="count"><call-template name="level"/></with-param>
        </call-template>
    </variable>
    <text>&#xA;</text>
    <value-of select="$wikiheader"/>
    <text>{{section|</text>
        <value-of select="@id"/><text>|</text>
        <value-of select="normalize-space(concat(enum, ' ', header))"/>
        <text>}}</text>
    <value-of select="$wikiheader"/>
    <text>&#xA;</text>
    <apply-templates select="*[not(self::enum or self::header)]"/>
</template>

</stylesheet>






