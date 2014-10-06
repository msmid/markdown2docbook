<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY LF "<xsl:text>&#xA;</xsl:text>">
]>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:d="http://docbook.org/ns/docbook"
    xmlns:md2doc="http://allwe.cz/ns/markdown2docbook" 
    exclude-result-prefixes="xs d md2doc"
    xpath-default-namespace="">
    
    <!--importing sheet with functions-->
    <xsl:import href="md2doc-functions.xsl"/>

    <!--dobry k ovladani vice formatu vystupu-->
    <xsl:output name="docbook" encoding="utf-8" method="xml" indent="yes"/>

    <!--Parameters for input text file NOTE: přidej required-->
    <xsl:param name="uri" as="xs:anyURI"/>
    <xsl:param name="encoding" as="xs:string" select="string('UTF-8')"/>
    <xsl:param name="topLevelTag" as="xs:string"/>

    <!--PHASE ONE-->
    <!--Step one; load, check and tokenize into lines input markdown document-->
    <xsl:variable name="input" select="md2doc:check-input('../test/in/test.md','utf-8')"/>
    <xsl:variable name="tokens" select="md2doc:tokenize-input($input)"/>
    <xsl:variable name="raw-xml" select="md2doc:build-lines($tokens)"/>   
    <!--Step two; parse lines into block-level elements-->
    <xsl:variable name="parsed-to-block" select="md2doc:do-block($raw-xml)"/>      
    <!--Step two; parse text nodes into inline elements-->
    <xsl:variable name="inlined" select="md2doc:do-inline($parsed-to-block)"/>
    
    <!--        <xsl:copy-of select="md2doc:parse-links($parsed-to-block)"/>-->
    

    <!--PHASE TWO-->
    
    <!--Volani templatu na predelani myho xml na html a pote docbook-->



    <!--Main template to be called at the start of transformation-->
    <xsl:template name="main">
        
<!--        <xsl:copy-of select="md2doc:do-references($parsed-to-block,'link','1')"/>-->
        
        <!--OUTPUT PHASE-->
        <xsl:result-document href="../test/out/output2.xml" format="docbook">&LF;
            <xsl:text>Parsovaný do blocku</xsl:text>&LF;
            <xsl:copy-of select="$parsed-to-block"/>
        </xsl:result-document>
        <xsl:result-document href="../test/out/output3.xml" format="docbook">&LF;
            <xsl:text>Parsovaný pres volani funkce do-inline</xsl:text>&LF;
            <xsl:copy-of select="md2doc:do-inline($parsed-to-block)"/>
        </xsl:result-document>
        <xsl:result-document href="../test/out/output.xml" format="docbook">&LF;
        
<!--            <xsl:copy-of select="$inlined"/>-->
<!--            <xsl:copy-of select="$parsed-full"/>-->
<!--            <xsl:copy-of select="$parsed-to-block"/>-->
<!--            <xsl:apply-templates select="$inlined" mode="html"/>-->
            
            <xsl:call-template name="md2doc:build-html">
                <xsl:with-param name="input" select="$inlined"/>
            </xsl:call-template>
            
            <xsl:fallback>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(3, error)"/>
                </xsl:message>
            </xsl:fallback>
            
        </xsl:result-document>
        
    </xsl:template>
    
    <!--MODY TEMPLATU
    - muzou ovladat vystup/format vystupu a podobne-->
 
    <!--____TEMPLATES__________________________________________________________________________-->
    
    <!--MODE INLINE-->
    
    <xsl:template match="node()|@*" mode="#all" priority="-1">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="text()" mode="do-inline">
        <!--Tady potrebuju udelat aby mi to proslo tolikrat kolikrat mam inline elementu
        tedy:
        - link (basic, reference), code, strong, emphasis, img (basic, reference)-->
        <!--link a image jsou temer stejny az na to ze u image zacina markup "![asdd] ..."-->
        <!--<xsl:analyze-string select="." regex="\[(link)\]\[(1)\]">
            <xsl:matching-substring>
                <xsl:element name="a">
                    <xsl:attribute name="href">
                        <!-\-<xsl:value-of select="key('link-id', regex-group(2))"/>-\->
                        <xsl:value-of select="md2doc:do-references($parsed-to-block,regex-group(1),regex-group(2))"/>
                    </xsl:attribute>
                    <xsl:attribute name="title">
                        <xsl:value-of select="'title'"/>
                    </xsl:attribute>
                    <xsl:copy-of select="regex-group(1)"/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-strong(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>   -->  
        <xsl:copy-of select="md2doc:parse-strong(.)"/>
    </xsl:template>
    
    <xsl:template match="p" mode="do-cleanup">
        <xsl:choose>
            <xsl:when test="matches(., '^ {0,3}\[(\d|\w)+\]: ?')">
                <!--Tady nic nebude a <p> s referenci se nefoukne do finalniho documentu-->
                <xsl:copy-of select="."/>
                <!--tohle funguje (jakoze to nic nedela ale nehlasi to tu context chybu-->
                <xsl:value-of select="key('link-id', regex-group(2))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:key name="link-id" match="p[matches(.,'\[1\]:')]">
        <xsl:analyze-string select="." regex="[(1)]: (www.neco.cz) .title.">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:key>
    
    <xsl:key name="link-url" match="p[matches(.,'\[1\]:')]">
        <xsl:analyze-string select="." regex="[(1)]: (www.neco.cz) .title.">
            <xsl:matching-substring>
                <xsl:value-of select="regex-group(2)"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:key>
    
    <!--____PHASE_TWO_TEMPLATES________________________________________________________________-->
    
    <xsl:template name="md2doc:build-html">
        <xsl:param name="input"/>
        <html>
            <head>
                <title>Foo</title>
            </head>
            <body>
                <xsl:apply-templates select="$input" mode="html"/>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="codeX" mode="html">
        <pre>
            <xsl:copy-of select="."/>
        </pre>
    </xsl:template>
    
    <xsl:template match="h1">
        <h1><xsl:value-of select="."/></h1>
    </xsl:template>
    
    <xsl:template match="li">
        <li><xsl:value-of select="."/></li>
    </xsl:template>
    
    <!--In xhtml blockquote can have only block level element as a child-->
    <xsl:template match="blockquotex">
        <blockquote>
            <p>
                
            </p>
        </blockquote>
    </xsl:template>
    
    <!--TRANSFORM LISTU
    EDIT 22/9 - 1607: NEJSPIS TOHLE LZE UDELAT EFEKTIVNEJI PRES FOR-EACH-GROUP
    We need to transform "lined" raw xml document into well-formed document e.g. merge and wrap block elements
    around their content-->
    
<!--    <xsl:key name="kFollowing" match="li[preceding-sibling::*[1][self::li]]"
        use="generate-id(preceding-sibling::li
        [not(preceding-sibling::*[1][self::li])][1])"/>
    
    <xsl:template match="node()|@*" name="identity">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="li[not(preceding-sibling::*[1][self::li])]">
        <xsl:element name="{@type}">
            <xsl:call-template name="identity"/>
            <xsl:apply-templates mode="copy" select="key('kFollowing',generate-id())"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="li[preceding-sibling::*[1][self::li]]"/>
    
    <xsl:template match="li" mode="copy">
        <xsl:call-template name="identity"/>
    </xsl:template>-->
 
    <xsl:variable name="inline">
        <md2doc:markup>
<!--            <name regex="">em</name>-->
            <name regex="(\*{{2}}\w+\*{{2}})|(_{{2}}\w+_{{2}})">strong</name>
<!--            <name regex="(\*{{1}}\w+\*{{1}})|(_{{1}}\w+_{{1}})">em</name>-->
            <!--<name regex="">code</name>
            <name regex="" atributes="src alt">image</name>
            <name regex="" atributes="href title">link</name>-->
<!--            (\*{{2}}\w+\*{{2}})|(_{{2}}\w+_{{2}})-->
        </md2doc:markup>
    </xsl:variable>
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
<!--  OBSOLETE  -->
<!--    
    <!-\-Variable that holds input text to be parsed-\->
    <xsl:variable name="input" as="xs:string" select="md2doc:checkInput('../test/test.md',$encoding)"/>
    
    <!-\-First, input is tokenized into lines to be further parsed-\->
    <xsl:variable name="lines" as="xs:string*" select="tokenize($input,'\r')"/>
    
    <!-\-Temporary document tree, regex is matching every block element and is ran over every line, 
        representing parsing function-\->
    <!-\-EDIT: xsl:for-each prisel o atribut as="element(line)*"-\->
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
    
    <!-\-function that tests if supplied input file is non-conflicting. If true, file is read, if false,
    XSLT fails with error message-\->
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

-->

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

</xsl:transform>
