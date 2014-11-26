<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns="http://docbook.org/ns/docbook"
    xmlns:xl="http://www.w3.org/1999/xlink"
    xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"
    exclude-result-prefixes="xs xl md2doc"
    xpath-default-namespace="">
    
    <!--
        TEMPLATE library stylesheet
        
        Markdown Parser in XSLT2 Copyright 2014 Martin Šmíd
        This code is under MIT licence, see more at https://github.com/MSmid/markdown2docbook
    -->
    
    <!--
    ! Main template which starts transformation from HTML into DocBook. Params can be left empty (eg, '').
    ! It decides if result document should be wrapped in root element.
    !
    ! @param $root-element defines what root element should be used
    ! @param $headline-element defines what headline element should be used
    -->
    <xsl:template match="root" mode="md2doc:transform">
        <xsl:param name="root-element"/>
        <xsl:param name="headline-element"/>
        <xsl:choose>
            <xsl:when test="$root-element != ''">
                <xsl:element name="{$root-element}" namespace="http://docbook.org/ns/docbook">
                    <xsl:attribute name="version" select="5"/>
                    <xsl:if test="boolean(/root/*//a)">
                        <xsl:namespace name="xl">http://www.w3.org/1999/xlink</xsl:namespace>  
                    </xsl:if>   
                    <title><xsl:value-of select="$root-element"/></title>
                    <xsl:call-template name="md2doc:headline-grouping">
                        <xsl:with-param name="headline-element" select="$headline-element"/>
                        <xsl:with-param name="root-element" select="$root-element"/>
                    </xsl:call-template>
                </xsl:element>    
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="md2doc:headline-grouping">
                    <xsl:with-param name="headline-element" select="$headline-element"/>
                    <xsl:with-param name="root-element" select="$root-element"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!--
    ! It is used for grouping elements by headlines h1-6. These groups are processed further.
    ! HTML document created from Markdown parsing is considered as "flat". Transformation into DocBook 
    ! wouldn't do much to its semantic structure, so grouping by headlines can produce DocBook with chapters, sections
    ! and etc.
    !
    ! @param $root-element defines what root element should be used
    ! @param $headline-element defines what headline element should be used
    -->
    <xsl:template name="md2doc:headline-grouping">
        <xsl:param name="headline-element"/>
        <xsl:param name="root-element"/>
        <xsl:for-each-group select="*" 
            group-starting-with="h1|
            h2[not(preceding-sibling::h1)]|
            h3[not(preceding-sibling::h2)]|
            h4[not(preceding-sibling::h3)]|
            h5[not(preceding-sibling::h4)]|
            h6[not(preceding-sibling::h5)]
            ">                    
            <xsl:apply-templates select="." mode="md2doc:group">
                <xsl:with-param name="headline-element" select="$headline-element"/>
                <xsl:with-param name="root-element" select="$root-element"/>
            </xsl:apply-templates>
        </xsl:for-each-group>
    </xsl:template>
    
    <!--
    ! Template which processes groups starting with headline. When document contains element <a>, it adds
    ! xlink namespace to root or headline element.
    !
    ! @param $root-element defines what root element should be used
    ! @param $headline-element defines what headline element should be used
    -->
    <xsl:template match="h1|h2|h3|h4|h5|h6" mode="md2doc:group">
        <xsl:param name="headline-element"/>
        <xsl:param name="root-element"/>
        <xsl:variable name="this" select="name()"/>
        <xsl:variable name="next" select="translate($this, '123456', '234567')"/>
        <xsl:element name="{
            if ($headline-element != '')
            then ( 
                if ($this eq 'h1') 
                then $headline-element
                else concat('sect',translate(replace($this,'h',''),'23456','12345'))
            )
            else 'section'
            }">
            <xsl:if test="$root-element eq '' and $this eq 'h1'">
                <xsl:attribute name="version" select="5"/>
                <xsl:if test="boolean(/root//*[a])">
                    <xsl:namespace name="xl">http://www.w3.org/1999/xlink</xsl:namespace>  
                </xsl:if>             
            </xsl:if>
            <title><xsl:apply-templates mode="md2doc:transform"/></title>
            <xsl:variable name="group" select="string-join(current-group(),'')"/>
            <xsl:if test="string-length(.) eq string-length($group)">
                <para></para>
            </xsl:if>
            <xsl:for-each-group select="current-group() except ." group-starting-with="*[name() = $next]">
                <xsl:apply-templates select="." mode="md2doc:group">
                    <xsl:with-param name="headline-element" select="$headline-element"/>
                    <xsl:with-param name="root-element" select="$root-element"/>
                </xsl:apply-templates>
            </xsl:for-each-group>
        </xsl:element>
    </xsl:template> 
    
    <xsl:template match="h1|h2|h3|h4|h5|h6" mode="md2doc:transform">
        <para><xsl:apply-templates mode="md2doc:transform"/></para>
    </xsl:template>
    
    <xsl:template match="p" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="p" mode="md2doc:transform">
        <para><xsl:apply-templates select="node()|@*" mode="md2doc:transform"/></para>
    </xsl:template>
    
    <xsl:template match="blockquote" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="blockquote" mode="md2doc:transform">
        <blockquote>
            <xsl:choose>
                <xsl:when test="p">
                    <xsl:apply-templates select="node()|@*" mode="md2doc:transform"/>
                </xsl:when>
                <xsl:otherwise>
                    <para><xsl:apply-templates select="node()|@*" mode="md2doc:transform"/></para>
                </xsl:otherwise>
            </xsl:choose>
        </blockquote>
    </xsl:template>
    
    <xsl:template match="blockquote/h1" mode="md2doc:transform">
        <title><xsl:apply-templates mode="md2doc:transform"/></title>          
    </xsl:template>
    
    <xsl:template match="blockquote/h2|blockquote/h3|blockquote/h4|blockquote/h5|blockquote/h6" mode="md2doc:transform">
        <para><xsl:apply-templates mode="md2doc:transform"/></para>          
    </xsl:template>
    
    <xsl:template match="ul" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="ul" mode="md2doc:transform">
        <itemizedlist>
            <xsl:apply-templates mode="md2doc:transform"/>
        </itemizedlist>
    </xsl:template>
    
    <xsl:template match="ol" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="ol" mode="md2doc:transform">
        <orderedlist numeration="arabic">
            <xsl:apply-templates select="*" mode="md2doc:transform"/>
        </orderedlist>
    </xsl:template>
    
    <xsl:template match="li" mode="md2doc:transform">
        <listitem>
            <xsl:choose>
                <xsl:when test="p">
                    <xsl:apply-templates select="node()|@*" mode="md2doc:transform"/>
                </xsl:when>
                <xsl:otherwise>
                    <para><xsl:apply-templates select="node()|@*" mode="md2doc:transform"/></para>
                </xsl:otherwise>
            </xsl:choose>
        </listitem>
    </xsl:template>
    
    <xsl:template match="li/h1|li/h2|li/h3|li/h4|li/h5|li/h6" mode="md2doc:transform">
        <xsl:apply-templates mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="pre" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="pre" mode="md2doc:transform">
        <xsl:apply-templates mode="md2doc:transform"/>    
    </xsl:template>
    
    <xsl:template match="code[ancestor::pre]" mode="md2doc:transform">
        <programlisting> 
            <xsl:value-of select="."/>
        </programlisting>
    </xsl:template>
    
    <xsl:template match="hr" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="hr" mode="md2doc:transform"/>
    
    <xsl:template match="code|samp" mode="md2doc:transform">
        <computeroutput>
            <xsl:value-of select="." disable-output-escaping="yes"/>
        </computeroutput>
    </xsl:template>
    
    <xsl:template match="em|mark" mode="md2doc:transform">
        <emphasis>
            <xsl:apply-templates select="node()|@*" mode="md2doc:transform"/>
        </emphasis>
    </xsl:template>
    
    <xsl:template match="strong" mode="md2doc:transform">
        <emphasis role="strong">
            <xsl:apply-templates select="node()|@*" mode="md2doc:transform"/>
        </emphasis>
    </xsl:template>
    
    <xsl:template match="img" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="img" mode="md2doc:transform">
        <mediaobject>
            <alt><xsl:value-of select="@alt"/></alt>
            <imageobject>
                <imagedata fileref="{@src}"/>
            </imageobject>
            <xsl:if test="@title != ''">
                <textobject>
                    <phrase><xsl:value-of select="@title"/></phrase>
                </textobject>
            </xsl:if>
        </mediaobject>
    </xsl:template>
    
    <xsl:template match="p/img" mode="md2doc:transform">
        <inlinemediaobject>
            <alt><xsl:value-of select="@alt"/></alt>
            <imageobject>
                <imagedata fileref="{@src}"/>
            </imageobject>
            <xsl:if test="@title != ''">
                <textobject>
                    <phrase><xsl:value-of select="@title"/></phrase>
                </textobject>
            </xsl:if>
        </inlinemediaobject>
    </xsl:template>
    
    <xsl:template match="a" mode="md2doc:transform">
        <link>
            <xsl:attribute name="xl:href">
                <xsl:value-of select="@href"/>
            </xsl:attribute>
            <xsl:if test="@title != ''">
<!--                <alt><xsl:value-of select="@title"/></alt>-->
                <xsl:attribute name="xl:title">
                    <xsl:value-of select="@title"/>
                </xsl:attribute>
            </xsl:if>         
            <xsl:apply-templates select="node()" mode="md2doc:transform"/>
        </link>
    </xsl:template>
    
    <xsl:template match="br" mode="md2doc:transform">
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template match="address|article|aside|body|button|div|
        figure|fieldset|footer|form|header|map|nav|object|section|
        video|script|noscript|iframe" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/> 
    </xsl:template>

    <xsl:template match="article|aside|body|button|div|
        fieldset|footer|form|header|map|nav|object|section|
        script|noscript|iframe" mode="md2doc:transform">
        <para><xsl:apply-templates select="node()|@*" mode="md2doc:transform"/></para>
    </xsl:template>
    
    <xsl:template match="address" mode="md2doc:transform">
        <address>
            <xsl:apply-templates mode="md2doc:transform"/>
        </address>
    </xsl:template>
    
    <xsl:template match="video" mode="md2doc:transform">
        <mediaobject>
            <videoobject>
                <videodata fileref="{@src}"/>
            </videoobject>
            <textobject>
                <para><xsl:value-of select="text()"/></para>
            </textobject>
        </mediaobject>
    </xsl:template>
    
    <xsl:template match="embed[starts-with(@type,'video')]" mode="md2doc:transform">
        <mediaobject>
            <videoobject>
                <videodata fileref="{@src}"/>
            </videoobject>
        </mediaobject>
    </xsl:template>
    
    <xsl:template match="figure" mode="md2doc:transform">
        <figure>
            <title><xsl:apply-templates select="figcaption/node()|@*" mode="md2doc:transform"/></title>
            <xsl:apply-templates select="node()|@*" mode="md2doc:transform"/>
        </figure>
    </xsl:template>
    
    <xsl:template match="figure/figcaption" mode="md2doc:transform"/>
    
    <!--Table transform-->   
    <xsl:template match="table" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="table" mode="md2doc:transform">
        <xsl:choose>
            <xsl:when test="caption">
                <table>
                    <xsl:apply-templates mode="md2doc:transform"/>
                </table>
            </xsl:when>
            <xsl:otherwise>
                <informaltable>
                    <xsl:apply-templates mode="md2doc:transform"/>
                </informaltable>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="thead" mode="md2doc:transform">
        <thead>
            <xsl:apply-templates mode="md2doc:transform"/>
        </thead>
    </xsl:template>
    
    <xsl:template match="tbody" mode="md2doc:transform">
        <tbody>
            <xsl:apply-templates mode="md2doc:transform"/>
        </tbody>
    </xsl:template>
    
    <xsl:template match="tfoot" mode="md2doc:transform">
        <tfoot>
            <xsl:apply-templates mode="md2doc:transform"/>
        </tfoot>
    </xsl:template>
    
    <xsl:template match="caption" mode="md2doc:transform">
        <caption>
            <xsl:apply-templates mode="md2doc:transform"/>
        </caption>
    </xsl:template>
    
    <xsl:template match="tr" mode="md2doc:transform">
        <tr>
            <xsl:for-each select="th">
                <th>
                    <xsl:apply-templates mode="md2doc:transform"/>
                </th>
            </xsl:for-each>
            <xsl:for-each select="td">
                <td>
                    <xsl:apply-templates mode="md2doc:transform"/>
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>
    
    <!--Definition list transform-->
    <xsl:template match="dl" mode="md2doc:group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="dl" mode="md2doc:transform">
        <variablelist>
            <varlistentry>
                <xsl:for-each select="dt">
                    <term>
                        <xsl:apply-templates mode="md2doc:transform"/>
                    </term>
                </xsl:for-each>
                <xsl:for-each select="dd">
                    <listitem>
                        <para><xsl:apply-templates mode="md2doc:transform"/></para>
                    </listitem>
                </xsl:for-each>
            </varlistentry>
        </variablelist>
    </xsl:template>
    
    <!--HTML inline elements-->
    <xsl:template match="b|i|ins|span|small|dfn|object|textarea|script|button|label" mode="md2doc:transform">
        <phrase><xsl:apply-templates mode="md2doc:transform"/></phrase>
    </xsl:template>
    
    <xsl:template match="abbr" mode="md2doc:transform">
        <abbrev>
            <xsl:apply-templates mode="md2doc:transform"/>
        </abbrev>
    </xsl:template>
    
    <xsl:template match="cite" mode="md2doc:transform">
        <citation>
            <xsl:apply-templates mode="md2doc:transform"/>
        </citation>
    </xsl:template>
    
    <xsl:template match="del" mode="md2doc:transform">
        <emphasis role="strikethrough">
            <xsl:apply-templates mode="md2doc:transform"/>
        </emphasis>
    </xsl:template>
    
    <xsl:template match="kbd" mode="md2doc:transform">
        <keycap>
            <xsl:apply-templates mode="md2doc:transform"/>
        </keycap>
    </xsl:template>
    
    <xsl:template match="var" mode="md2doc:transform">
        <varname>
            <xsl:apply-templates mode="md2doc:transform"/>
        </varname>
    </xsl:template>
    
    <xsl:template match="q" mode="md2doc:transform">
        <quote>
            <xsl:apply-templates mode="md2doc:transform"/>
        </quote>
    </xsl:template>
    
    <xsl:template match="sub" mode="md2doc:transform">
        <subscript>
            <xsl:apply-templates mode="md2doc:transform"/>
        </subscript>
    </xsl:template>
    
    <xsl:template match="sup" mode="md2doc:transform">
        <superscript>
            <xsl:apply-templates mode="md2doc:transform"/>
        </superscript>
    </xsl:template>
    
</xsl:stylesheet>