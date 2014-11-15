<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns="http://docbook.org/ns/docbook"
    xmlns:xl="http://www.w3.org/1999/xlink"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"
    exclude-result-prefixes="xs xl html md2doc"
    xpath-default-namespace="">
    
    <xsl:template match="root" mode="md2doc:transform">
        <xsl:param name="root-element"/>
        <xsl:param name="headline-element"/>
        <xsl:choose>
            <xsl:when test="$root-element != ''">
                <xsl:element name="{$root-element}">
                    <xsl:attribute name="version" select="5"/>
                    <xsl:if test="boolean(/root/*//a)">
                        <xsl:namespace name="xl">http://www.w3.org/1999/xlink</xsl:namespace>  
                    </xsl:if>   
                    <xsl:if test="
                        ($root-element eq 'chapter' or
                        $root-element eq 'article' or
                        $root-element eq 'preface' or
                        $root-element eq 'glossary' or
                        $root-element eq 'dedication' or
                        $root-element eq 'bibliography')
                        ">
                        <title><xsl:value-of select="$root-element"/></title>
                    </xsl:if>
                    <xsl:call-template name="headline-grouping">
                        <xsl:with-param name="headline-element" select="$headline-element"/>
                        <xsl:with-param name="root-element" select="$root-element"/>
                    </xsl:call-template>
                </xsl:element>    
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="headline-grouping">
                    <xsl:with-param name="headline-element" select="$headline-element"/>
                    <xsl:with-param name="root-element" select="$root-element"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="headline-grouping">
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
            <xsl:apply-templates select="." mode="group">
                <xsl:with-param name="headline-element" select="$headline-element"/>
                <xsl:with-param name="root-element" select="$root-element"/>
            </xsl:apply-templates>
            <!--            <xsl:message select="'headline grouping: ',."/>-->
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template match="h1|h2|h3|h4|h5|h6" mode="group">
        <xsl:param name="headline-element"/>
        <xsl:param name="root-element"/>
        <xsl:variable name="this" select="name()"/>
        <xsl:variable name="next" select="translate($this, '123456', '234567')"/>
        <xsl:element name="{
            if ($this eq 'h1' and $headline-element != '') 
            then $headline-element 
            else concat('sect',translate(replace($this,'h',''),'23456','12345'))
            }">
            <xsl:if test="$root-element eq ''">
                <xsl:attribute name="version" select="5"/>
                <xsl:if test="boolean(/root//*[a])">
                    <xsl:namespace name="xl">http://www.w3.org/1999/xlink</xsl:namespace>  
                </xsl:if>             
            </xsl:if>
            <title><xsl:apply-templates select="node()|@*" mode="md2doc:transform"/></title>
            <xsl:for-each-group select="current-group() except ." group-starting-with="*[name() = $next]">
                <xsl:apply-templates select="." mode="group"/>
                <!--<xsl:message>hX rule: <xsl:copy-of select="."/></xsl:message>-->
            </xsl:for-each-group>
        </xsl:element>
    </xsl:template> 
    
    <xsl:template match="p" mode="group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
        <!--        <xsl:message select="'Rule * group mode: ', current-group()"/>-->
    </xsl:template>
    
    <xsl:template match="p" mode="md2doc:transform">
        <para><xsl:apply-templates select="node()|@*" mode="md2doc:transform"/></para>
        <!--        <xsl:message select="'Rule p no mode: ', ."/>-->
    </xsl:template>
    
    <xsl:template match="blockquote" mode="group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="blockquote" mode="md2doc:transform">
        <blockquote>
            <xsl:apply-templates mode="md2doc:transform"/>
        </blockquote>
    </xsl:template>
    
    <xsl:template match="blockquote/h1" mode="md2doc:transform">
        <title><xsl:apply-templates mode="md2doc:transform"/></title>
    </xsl:template>
    
    <xsl:template match="ul" mode="group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="ul" mode="md2doc:transform">
        <itemizedlist>
            <xsl:apply-templates mode="md2doc:transform"/>
        </itemizedlist>
    </xsl:template>
    
    <xsl:template match="ol" mode="group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="ol" mode="md2doc:transform">
        <orderedlist>
            <xsl:apply-templates select="*" mode="md2doc:transform"/>
        </orderedlist>
    </xsl:template>
    
    <xsl:template match="li" mode="md2doc:transform">
        <listitem>
            <xsl:apply-templates select="*" mode="md2doc:transform"/>
        </listitem>
    </xsl:template>
    
    <xsl:template match="li/h1" mode="md2doc:transform">
        <xsl:apply-templates mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="pre" mode="group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="pre" mode="md2doc:transform">
        <example>
            <xsl:apply-templates mode="md2doc:transform"/>    
        </example>
    </xsl:template>
    
    <xsl:template match="code[ancestor::pre]" mode="md2doc:transform">
        <programlisting>         
            <xsl:value-of select="." disable-output-escaping="no"/>
        </programlisting>
    </xsl:template>
    
    <xsl:template match="hr" mode="group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>
    </xsl:template>
    
    <xsl:template match="hr" mode="md2doc:transform"/>
    
    <xsl:template match="textarea" mode="group">
        <xsl:apply-templates select="current-group()" mode="md2doc:transform"/>      
    </xsl:template>
    
    <xsl:template match="textarea" mode="md2doc:transform">
        <example>
            <programlisting language="html">
                <xsl:value-of select="text()" disable-output-escaping="no"/> 
            </programlisting>
        </example>          
    </xsl:template>
    
    <!--During seriliazation, this template will cause that textarea string is turned into html-->
    <!--<xsl:template match="textarea" mode="md2doc:transform">
        <xsl:value-of select="text()" disable-output-escaping="yes"/>      
    </xsl:template>-->
    
    <xsl:template match="code" mode="md2doc:transform">
        <computeroutput>
            <xsl:value-of select="." disable-output-escaping="yes"/>
        </computeroutput>
    </xsl:template>
    
    <xsl:template match="em|strong" mode="md2doc:transform">
        <emphasis>
            <xsl:apply-templates select="node()|@*" mode="md2doc:transform"/>
        </emphasis>
    </xsl:template>
    
    <xsl:template match="img" mode="md2doc:transform">
        <inlinemediaobject>
            <imageobject>
                <imagedata fileref="{@src}"/>
            </imageobject>
            <alt><xsl:value-of select="@alt"/></alt>
            <!--existuje i alt tag a kam dam title informaci?-->
        </inlinemediaobject>
    </xsl:template>
    
    <xsl:template match="a" mode="md2doc:transform">
        <link>
            <xsl:attribute name="xl:href">
                <xsl:value-of select="@href"/>
            </xsl:attribute>
            <xsl:if test="@title = ''">
                <alt><xsl:value-of select="@title"/></alt>
            </xsl:if>         
            <xsl:apply-templates select="node()" mode="md2doc:transform"/>
        </link>
    </xsl:template>
    
    <xsl:template match="node()|@*" name="identity" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>