<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY LF "<xsl:text>&#xA;</xsl:text>">
]>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:d="http://docbook.org/ns/docbook"
    xmlns:md2doc="http://allwe.cz/ns/markdown2docbook" exclude-result-prefixes="xs d md2doc"
    xpath-default-namespace="">
    
    <!--importing sheet with functions-->
    <xsl:import href="md2doc-functions.xsl"/>

    <xsl:output name="docbook" encoding="utf-8" method="xml" indent="yes"/>

    <!--Parameters for input text file NOTE: přidej required-->
    <xsl:param name="uri" as="xs:anyURI"/>
    <xsl:param name="encoding" as="xs:string" select="string('UTF-8')"/>
    <xsl:param name="topLevelTag" as="xs:string"/>

    

    <!--TODO: pripravit XSLT na mody reprezentujici dve faze: 1. faze = raw xml output, 2. faze = docbook
              vyuzit temporary dokumentu na predavani outputu mezi fazemi-->

    <!--Main template to be called at the start of transformation-->
    <xsl:template name="main">
        <xsl:result-document href="../test/out/output.xml" format="docbook" method="xml">&LF;
            
                <xsl:variable name="input" select="md2doc:check-input('../test/in/test.md','utf-8')"/>
                <xsl:variable name="tokens" select="md2doc:tokenize-input($input)"/>
                <xsl:variable name="lines" select="md2doc:build-lines($tokens)"/>
                <xsl:variable name="out" select="md2doc:do-block($lines)"/>
<!--                <xsl:variable name="out2" select="md2doc:build-HTML($out)"/>-->
            
<!--                <xsl:variable name="out2" select="md2doc:parse-blockquotes($lines)"/>-->
<!--                <xsl:variable name="out" select="md2doc:parse($lines)"/>-->
            
            <pre-html>
                <xsl:copy-of select="$out"/>
            </pre-html>
                
            
            <xsl:fallback>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(3, error)"/>
                </xsl:message>
            </xsl:fallback>
        </xsl:result-document>
    </xsl:template>
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
<!--  OBSOLETE  -->
    
    <!--Variable that holds input text to be parsed-->
    <xsl:variable name="input" as="xs:string" select="md2doc:checkInput('../test/test.md',$encoding)"/>
    
    <!--First, input is tokenized into lines to be further parsed-->
    <xsl:variable name="lines" as="xs:string*" select="tokenize($input,'\r')"/>
    
    <!--Temporary document tree, regex is matching every block element and is ran over every line, 
        representing parsing function-->
    <!--EDIT: xsl:for-each prisel o atribut as="element(line)*"-->
    <xsl:variable name="rawXML">
        <xsl:for-each select="$lines">
            <xsl:variable name="line" select="."/>
            <xsl:for-each select="$regex/*[@type='block']">
                <xsl:analyze-string select="$line" flags="xm" regex="{.}">
                    <xsl:matching-substring>
                        <line markdown="{regex-group(1)}" content="{regex-group(2)}"/>&LF;
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:choose>
                            <xsl:when test="matches(.,'^()(.+|[\r\n\t])$')">
                                <line markdown="" content="{.}"/>        
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message select="md2doc:alert(2, 'error')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:variable>
    
    <!--function that tests if supplied input file is non-conflicting. If true, file is read, if false,
    XSLT fails with error message-->
    <xsl:function name="md2doc:checkInput">
        <xsl:param name="uri"/>
        <xsl:param name="encoding"/>
        <xsl:choose>
            <xsl:when test="unparsed-text-available($uri, $encoding)">
                <xsl:value-of select="unparsed-text($uri, $encoding)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:value-of select="md2doc:alert(1, 'error')"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!--Lookup data-->
    <!--<xsl:variable name="errors">
        <message no="1">Error with input file: incorrect encoding or missing file</message>
        <message no="2">Non-matching: </message>
    </xsl:variable>-->

    <!--<xsl:variable name="regex">
        <headline type="block">^(#+)(.+|[\r\n\t])$</headline>
        <headline type="block">^(=+)$</headline>
        <headline type="block">^(-+)$</headline>
        <paragraph type="block">^()(.+|[\r\n\t])$</paragraph>
        <inline markup="anchor"></inline>
    </xsl:variable>-->

    <xsl:template name="hr">
        &LF;<xsl:text>-------------------------------------------------------------</xsl:text>&LF; </xsl:template>

</xsl:transform>
