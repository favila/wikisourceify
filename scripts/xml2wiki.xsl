<?xml version="1.0" encoding="UTF-8" ?>
<!--
    xml2wiki.xsl
    Transform xml from deepbills into wiki text for wikisource
    Created by Francis Avila on 2013-04-04.
-->

<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cato="http://namespaces.cato.org/catoxml">

    <xsl:output encoding="UTF-8" method="text" />

    <xsl:variable name="people" select="document('../lookups/person.xml')"/>
    <xsl:variable name="committees" select="document('../lookups/committee.xml')"/>
    <xsl:variable name="federal-bodies" select="document('../lookups/federal-body.xml')"/>

    <xsl:key name="wikipedia" match="/items/item/@wikipedia" use="../@id"/>

    <xsl:template name="wikipedia-key">
        <xsl:param name="id"/>
        <xsl:param name="lookupdoc"/>
        <xsl:for-each select="$lookupdoc">
            <xsl:value-of select="key('wikipedia', $id)"/>
        </xsl:for-each>
    </xsl:template>


    <xsl:template match="/doc">
        <xsl:variable name="action-date" select="*[2]/form/action/action-date/@date"/>
{{Act of Congress
| congress       = <xsl:value-of select="docmeta/bill/@congress"/>
| session        = <xsl:value-of select="substring(*[2]/form/session, 1, 1)"/>
| pl             = 1
| title          = 
| override_previous = 
| statvolume     = 
| statpage       = 
| year           = <xsl:value-of select="substring($action-date, 1, 4)"/>
| month          = <xsl:value-of select="substring($action-date, 5, 2)"/>
| day            = <xsl:value-of select="substring($action-date, 7, 2)"/>
| bill           = <xsl:value-of select="docmeta/bill/@number"/>
| billtype       = <xsl:value-of select="docmeta/bill/@type"/>
| notes          = 
| resolution     = 
| purpose        = <xsl:value-of select="normalize-space(*[2]/form/official-title)"/>
}}
    <xsl:apply-templates select="*[2]"/>
    </xsl:template>

    <xsl:template match="distribution-code"/>

    <xsl:template match="congress|session|legis-num|legis-type|current-chamber|action-desc">
        {{Center|<xsl:apply-templates/>}}
    </xsl:template>

    <xsl:template match="section">

    </xsl:template>

    <xsl:template name="wikilink">
        <xsl:param name="id"/>
        <xsl:param name="idx"/>
        <xsl:variable name="wikipage">
            <xsl:call-template name="wikipedia-key">
                <xsl:with-param name="id" select="$id"/>
                <xsl:with-param name="lookupdoc" select="$idx"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$wikipage">
                [[<xsl:value-of select="$wikipage"/>|<xsl:apply-templates/>]]
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="sponsor | cosponsor | cato:entity-ref[@entity-type='person']">
        <xsl:call-template name="wikilink">
            <xsl:with-param name="id" select="(@name-id | @entity-id)[1]"/>
            <xsl:with-param name="idx" select="$people"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="cato:entity-ref[@entity-type='federal-body']">
        <xsl:call-template name="wikilink">
            <xsl:with-param name="id" select="(@entity-id | @entity-parent-id)[1]"/>
            <xsl:with-param name="idx" select="$federal-bodies"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="committee-name">
        <xsl:call-template name="wikilink">
            <xsl:with-param name="id" select="(@committee-id | @committee)[1]"/>
            <xsl:with-param name="idx" select="$committees"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="toc-entry[@idref]">
        <xsl:if test="@level='title'">*</xsl:if>
        <xsl:if test="@level='section'">**</xsl:if>
        [[#<xsl:value-of select="@idref"/>|<xsl:apply-templates/>]]
    </xsl:template>

    <xsl:template match="title[@id]">
        ={{section|<xsl:value-of select="@id"/>|<xsl:apply-templates/>}}=
    </xsl:template>

    <xsl:template match="section[@id]">
        =={{section|<xsl:value-of select="@id"/>|<xsl:apply-templates/>}}==
    </xsl:template>


</xsl:stylesheet>






