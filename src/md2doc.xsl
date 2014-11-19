<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY LF "<xsl:text>&#xA;</xsl:text>">
]>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:doc="http://docbook.org/ns/docbook"
    xmlns:xl="http://www.w3.org/1999/xlink" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"
    xmlns:d="data:,dpc"
    exclude-result-prefixes="xs xl html d md2doc" xpath-default-namespace="">

    <!--importing sheet with functions-->
    <xsl:import href="md2doc-functions.xsl"/>
    

    <xsl:output omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
    <xsl:output name="docbook" encoding="UTF-8" method="xml" indent="yes"/>
    <xsl:output name="html5" encoding="UTF-8" method="html" indent="yes"
        doctype-system="about:legacy-compat"/>
    <xsl:output name="xhtml" encoding="UTF-8" method="xhtml" indent="yes"
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
        omit-xml-declaration="yes"/>

    <!--Specifies if all document should be wrapped in element (like Book or perhaps Chapter)-->
    <xsl:param name="root-element" as="xs:string" select="'book'"/>
    <!--Specifies which docbook element should be match with h1 headlines-->
    <xsl:param name="headline-element" as="xs:string" select="'chapter'"/>

    <xsl:param name="input" as="xs:string" select="''"/>
    <xsl:param name="url-file" as="xs:string"/>
    <xsl:param name="encoding-file " as="xs:string" select="'UTF-8'"/>
    <xsl:param name="url-savepath" as="xs:string" select="''"/>

    <!--THIS SHEET IS ONLY FOR TESTING PURPOSES, IT CONTAINS INITIAL TEMPLATES-->
    <!--<xsl:include href="md2doc-test.xsl"/>-->

    <xsl:template name="main">
        <xsl:param name="input" as="xs:string" select="$input"/>
        <xsl:param name="encoding-file" as="xs:string" select="$encoding-file"/>
        <xsl:param name="root-element" as="xs:string" select="$root-element"/>
        <xsl:param name="headline-element" as="xs:string" select="$headline-element"/>
        <xsl:param name="url-savepath" as="xs:string" select="$url-savepath"/>

        <xsl:result-document href="{$url-savepath}" format="docbook">
            <xsl:processing-instruction name="xml-model">href="http://docbook.org/xml/5.0/rng/docbook.rng" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
            <xsl:processing-instruction name="xml-model">href="http://docbook.org/xml/5.0/rng/docbook.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron</xsl:processing-instruction>
            <xsl:choose>
                <xsl:when test="$encoding-file eq ''">
                    <xsl:sequence select="md2doc:convert($input, $root-element,$headline-element)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="md2doc:convert($input, $encoding-file, $root-element,$headline-element)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:result-document>
    </xsl:template>


    <xsl:template name="get-html">
        <xsl:param name="input" as="xs:string" select="$input"/>
        <xsl:param name="encoding-file" as="xs:string" select="$encoding-file"/>
        <xsl:param name="url-savepath" as="xs:string" select="$url-savepath"/>

        <xsl:result-document href="{$url-savepath}" format="xhtml" exclude-result-prefixes="doc">
            <html>
                <head>
                    <title></title>
                    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
                </head>
                <body>
                    <xsl:choose>
                        <xsl:when test="empty($encoding-file)">
                            <xsl:sequence select="md2doc:get-html($input)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="input"
                                select="md2doc:read-file($input, $encoding-file)"/>
                            <xsl:sequence select="md2doc:get-html($input)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>

    <xsl:template name="test">
        <xsl:param name="encoding-file" as="xs:string" select="'utf-8'"/>
        <xsl:param name="input" as="xs:string" select="'../test/in/test-frag.md'"/>

        <xsl:result-document href="../test/out/output.xml" format="xhtml" exclude-result-prefixes="doc">
            <!--<xsl:sequence select="md2doc:print-disclaimer()"/>-->
            <html>
                <head>
                    <title></title>
                    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
                </head>
                <body>
                    <xsl:choose>
                        <xsl:when test="$encoding-file eq ''">
                            <xsl:sequence select="md2doc:get-html($input)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="input"
                                select="md2doc:read-file($input, $encoding-file)"/>
                            <xsl:sequence select="md2doc:get-html($input)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </body>
            </html>
        </xsl:result-document>
        <xsl:result-document href="../test/out/output3.xml" format="docbook">
            <xsl:processing-instruction name="xml-model">href="http://docbook.org/xml/5.0/rng/docbook.rng" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
            <xsl:processing-instruction name="xml-model">href="http://docbook.org/xml/5.0/rng/docbook.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron</xsl:processing-instruction>
            <xsl:choose>
                <xsl:when test="$encoding-file eq ''">
                    <xsl:sequence select="md2doc:convert($input, $root-element, $headline-element)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="md2doc:convert($input, $encoding-file, $root-element, $headline-element)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:result-document>
        
        <!--<xsl:result-document href="../test/out/output2.xml" format="xhtml">
            <xsl:sequence select="d:htmlparse($input)"/>
        </xsl:result-document>-->
        
    </xsl:template>
    
    
    <xsl:variable name="md2doc:block-html" 
        select="string('article|aside|body|blockquote|button|canvas|div|dl|embed|figure|fieldset|footer|form|h[1-6]|header|map|nav|object|ol|p|pre|section|table|ul|video|script|noscript|iframe|math|ins')"/>
    


</xsl:transform>
