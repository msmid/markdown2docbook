<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY LF "<xsl:text>&#xA;</xsl:text>">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:md2doc="http://allwe.cz/ns/markdown2docbook"
    exclude-result-prefixes="xs md2doc"
    version="2.0">
        
    <!--FUNCTIONS LIBRARY-->
    
    <!-- Function that validates input file -->
    <xsl:function name="md2doc:check-input">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:param name="encoding" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="unparsed-text-available($uri, $encoding)">
                <xsl:sequence select="unparsed-text($uri, $encoding)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(1, 'error')"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="md2doc:tokenize-input">
        <xsl:param name="input" as="xs:string"/>
        <xsl:sequence select="tokenize($input,'\r')"/>
    </xsl:function>
    
    <xsl:function name="md2doc:build-lines">
        <xsl:param name="tokens" as="xs:string*"/>
        <xsl:for-each select="$tokens">
            <xsl:element name="line">
                <xsl:value-of select="if (. = $tokens[1]) then '&#xA;' else ''"/>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>
    
    <!--POZOR: markdown umi escapovat nekolik znaku navic umi i html prevest (kdyz uz do html prevadi)
    - escapovani by se melo odehrat jeste pred parsingem
    - otazka co s html v markdownu?
        - kdyby transformace delale nejdriv html a to do docbooku = problem solved-->
    
    <!--  FIRST STEP OF PHASE ONE
          Firstly, we need to parse block elements  -->
    <xsl:function name="md2doc:do-block">
        <xsl:param name="lines" as="xs:string*"/>
        <!--EDIT: zde by mohl byt xsl:document-->
        <xsl:sequence select="md2doc:parse-blockquotes($lines)"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-blockquotes">
        <xsl:param name="lines" as="xs:string*"/>
        <xsl:for-each select="$lines">
            <!--            <xsl:copy-of select="."/>-->
            <xsl:analyze-string select="." regex="^\n?(\s{{0,3}})&gt;\s?(.*)">
                <xsl:matching-substring>
                    <xsl:element name="blockquote">
                        <xsl:value-of select="regex-group(1)"/>
                        <xsl:copy-of select="md2doc:parse-blockquotes(normalize-space(regex-group(2)))"/>
                    </xsl:element>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:copy-of select="md2doc:parse-lists(.)"/>
                    <!--<xsl:message>
                        <xsl:text>PARSE-BQ: NON-MATCH: PARSE-HEADERS: </xsl:text>
                        <xsl:copy-of select="replace(., '\n',  '')"/>
                    </xsl:message>-->
                    <!--<xsl:element name="line">
                        <xsl:value-of select="replace(., '\n',  '/n')"/>
                    </xsl:element>-->
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:for-each>
    </xsl:function>
    
<!--    TODO: ve fazi kde budu prehtml transformovat lze udelat ze z ul ul udelam ul li strukturu-->
    <xsl:function name="md2doc:parse-lists">
        <xsl:param name="lines" as="xs:string*"/>
        <xsl:for-each select="$lines">
            <!--            <xsl:copy-of select="."/>-->
            <xsl:choose>
                <xsl:when test="matches(.,'^\n?\s{0,3}\d+?\.')">
                    <xsl:analyze-string select="." regex="^\n?\s{{0,3}}(\d+?)\.\s(.+|[\r\n\t])$">
                        <xsl:matching-substring>
                            <!--OL-->
                            <xsl:element name="li">
                                <xsl:attribute name="type">ol</xsl:attribute>
                                <xsl:copy-of select="md2doc:parse-lists(regex-group(2))"/>
                            </xsl:element>         
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:copy-of select="md2doc:parse-codeblocks(.)"/>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>            
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="matches(.,'^\n?([\*_-] {0,2}){3,}\s*$')">
                            <xsl:copy-of select="md2doc:parse-rulers(.)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:analyze-string select="." regex="^\n?\s{{0,3}}([\*\+-])\s(.+|[\r\n\t])$">
                                <xsl:matching-substring>
                                    <!--UL-->
                                    <xsl:element name="li">
                                        <xsl:attribute name="type">ul</xsl:attribute>
                                        <xsl:copy-of select="md2doc:parse-lists(regex-group(2))"/>
                                    </xsl:element>
                                </xsl:matching-substring>
                                <xsl:non-matching-substring>
                                    <xsl:copy-of select="md2doc:parse-codeblocks(.)"/>
                                </xsl:non-matching-substring>
                            </xsl:analyze-string>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-codeblocks">
        <xsl:param name="lines" as="xs:string*"/>
        <xsl:for-each select="$lines">
            <xsl:analyze-string select="." regex="^\n? {{4}}(.+)">
                <xsl:matching-substring>
                    <xsl:element name="code">
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:element>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:copy-of select="md2doc:parse-headers(.)"/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-headers">
        <xsl:param name="lines" as="xs:string*"/>
        <xsl:for-each select="$lines">
            <xsl:choose>
                <xsl:when test="matches(.,'^\n?#')">
                    <xsl:analyze-string select="." regex="^\n?(#+) *(.+) *">
                        <xsl:matching-substring>
                            <xsl:variable name="level" select="
                                if (string-length(regex-group(1)) &lt;= 6)
                                then string-length(regex-group(1))
                                else number(6)"/>
                            <xsl:element name="h{$level}">
                                <xsl:attribute name="type">atx</xsl:attribute>
                                <xsl:copy-of select="normalize-space(regex-group(2))"/>
                            </xsl:element>
                        </xsl:matching-substring>
                        <!--<xsl:non-matching-substring>^\n?(#+)(.*?)#+
                            <xsl:element name="line">
                                <xsl:value-of select="replace(., '\n',  '')"/>
                            </xsl:element>
                        </xsl:non-matching-substring>-->
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:analyze-string select="." regex="^\n?(-+?|=+?)$">
                        <xsl:matching-substring>
                            <xsl:variable name="level" select="
                                if (matches(.,'=')) 
                                then 1 
                                else 2"/>
                            <xsl:element name="h{$level}">
                                <xsl:attribute name="type">setext</xsl:attribute>
                                <xsl:copy-of select="regex-group(1)"/>
                            </xsl:element>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <!--<xsl:message>
                                <xsl:text>INPUT: </xsl:text><xsl:copy-of select="."/>
                            </xsl:message>-->
                            <!--<xsl:choose>
                                <xsl:when test="matches(.,'^\n')">
                                    <xsl:element name="line">
                                        <xsl:value-of select="replace(., '\n',  'newline')"/>
                                    </xsl:element>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>-->
                            <xsl:copy-of select="md2doc:parse-rulers(.)"/>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:otherwise>
            </xsl:choose>         
        </xsl:for-each>
    </xsl:function>
      
    <!--TODO: když je text nad třemi - ma to byt h2 ale je to p nasledovany hr. Chce to udelat aby to tak nebylo-->
    <xsl:function name="md2doc:parse-rulers">
        <xsl:param name="lines" as="xs:string*"/>
        <xsl:for-each select="$lines">
            <xsl:analyze-string select="." regex="^\n?([\*_-] {{0,2}}){{3,}}\s*$">
                <xsl:matching-substring>
                    <hr/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:choose>
                        <xsl:when test="matches(.,'^\s+$')">
                            <xsl:element name="blankline">
                                <xsl:value-of select="replace(., '\s+',  '')"/>
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="matches(.,'^\n')">
                            <xsl:element name="p">
                                <xsl:value-of select="replace(., '\n',  '')"/>
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:for-each>
    </xsl:function>
    
    <!--SECOND STEP OF PHASE ONE
    After block-level elements, we need to transform inline-level elements.-->  
    <xsl:function name="md2doc:do-inline">
        <xsl:param name="parsed-to-block" as="element()*"/>
<!--        <xsl:sequence select="md2doc:parse-emphasis($parsed-to-block)"/>-->
        <xsl:copy-of select="$parsed-to-block"/>
        <!--TODO-->
    </xsl:function>
    
    <xsl:function name="md2doc:parse-emphasis">
        <xsl:param name="parsed-to-block" as="element()*"/>
        <!--<xsl:for-each select="$parsed-to-block">
            <!-\-TODO-\->
        </xsl:for-each>-->
    </xsl:function>
    
    <xsl:function name="md2doc:parse-links">
        <xsl:param name="parsed-to-block" as="element()*"/>
        <!--<xsl:for-each select="$parsed-to-block">
            <!-\-TODO
                1. inline linky
                2. reference styl linky
                3. automatic linky
            -\->
        </xsl:for-each>-->
    </xsl:function>
    
    <xsl:function name="md2doc:parse-code">
        <xsl:param name="parsed-to-block" as="element()*"/>
        <!--<xsl:for-each select="$parsed-to-block">
            <!-\-TODO-\->
        </xsl:for-each>-->
    </xsl:function>
    
    <xsl:function name="md2doc:parse-images">
        <xsl:param name="parsed-to-block" as="element()*"/>
        <!--<xsl:for-each select="$parsed-to-block">
            <!-\-TODO-\->
        </xsl:for-each>-->
    </xsl:function>
    
    <!--PHASE TWO
    building formed xml document-->
    
    <!--Function that convert processed lines into document-node type temporary tree, which is more suitable for
    further transformation-->
    <xsl:function name="md2doc:convert">
        <xsl:param name="elements" as="element()*"/>
        <xsl:document>
        <xsl:copy-of select="$elements"/>
        </xsl:document>    
    </xsl:function>
    
    <xsl:function name="md2doc:build-HTML">
        <xsl:param name="parsed-to-block" as="document-node()"/>
<!--        <xsl:element name="html">-->
        <xsl:call-template name="md2doc:build-HTML">           
            <xsl:with-param name="parsed-input" select="$parsed-to-block"/>
        </xsl:call-template>
<!--        </xsl:element>-->
    </xsl:function>
    
    <xsl:template name="md2doc:build-HTML">
        <xsl:param name="parsed-input"/>
        <html>
            <head></head>
            <body>
                <xsl:apply-templates select="$parsed-input"/>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="p">
        <p><xsl:copy-of select="node()"/></p>
    </xsl:template>
    
    <xsl:template match="code">
        <pre>
            <xsl:copy-of select="."/>
        </pre>
    </xsl:template>
    
    <!--In xhtml blockquote can have only block level element as a child-->
    <xsl:template match="blockquotex">
        <blockquote>
            <p>

            </p>
        </blockquote>
    </xsl:template>
    
    <!--TRANSFORM LISTU-->
    <!--EDIT 22/9 - 1607: NEJSPIS TOHLE LZE UDELAT EFEKTIVNEJI PRES FOR-EACH-GROUP-->
    <!--We need to transform "lined" raw xml document into well-formed document e.g. merge and wrap block elements
    around their content-->
    <xsl:key name="kFollowing" match="li[preceding-sibling::*[1][self::li]]"
        use="generate-id(preceding-sibling::li
        [not(preceding-sibling::*[1][self::li])][1])"/>
    
    <xsl:template match="node()" name="identity">
        <xsl:copy>
            <xsl:apply-templates select="node()"/>
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
    </xsl:template>
    <!--END-->
    
    <!--TRANSFORM LISTU-->
    <!--<xsl:key name="kFollowing" match="li[preceding-sibling::*[1][self::li]]"
        use="generate-id(preceding-sibling::li
        [not(preceding-sibling::*[1][self::li])][1])"/>
    
    <xsl:template match="node()" name="identity">
        <xsl:copy>
            <xsl:apply-templates select="node()"/>
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
    <!--END-->
    
    <!-- testovací template (stejný jako na hlavním xsl)-->
    
    <xsl:output encoding="utf-8" method="xml" indent="yes"/>
    
    <xsl:template name="main">
<!--        <xsl:copy-of select="md2doc:prdik()"/>-->
<!--        <xsl:copy-of select="md2doc:parse-to-block(md2doc:tokenize-input(md2doc:check-input('../../test.md','utf-8')))"/>-->
<!--        <xsl:value-of select="if (matches('&lt;', '>')) then 'true' else 'false'"/>        -->
        
<!--        <xsl:value-of select="$input" disable-output-escaping="yes"/>-->
        
        <!--<xsl:value-of select="$lines"/>-->
<!--        <xsl:variable name="raw-block-xml" select="md2doc:parse-to-block($lines)"/>-->
<!--        <xsl:copy-of select="$raw-block-xml"/>-->
<!--        <xsl:copy-of select="md2doc:build-lines($tokens)"/>-->
        
        <!--<xsl:variable name="pom2" select="md2doc:parse-blockquotes($raw-xml)"/>
        <xsl:variable name="pom1" select="md2doc:parse-headers($raw-xml)"/>
        <xsl:variable name="out" select="md2doc:parse-lists($raw-xml)"/>-->
        <!--  Až potud se překlad skládá z dočasného xml, který v následujícím kroku je převeden na html   -->
        
        <xsl:variable name="input" select="md2doc:check-input('../test/in/test.md','utf-8')"/>
        <xsl:variable name="tokens" select="md2doc:tokenize-input($input)"/>
        <xsl:variable name="raw-xml" select="md2doc:build-lines($tokens)"/>        
        <xsl:variable name="parsed-to-block" select="md2doc:do-block($raw-xml)"/>
        <xsl:variable name="parsed-full" select="md2doc:do-inline($parsed-to-block)"/>
        <xsl:variable name="out2" select="md2doc:convert($parsed-full)"/>
        <xsl:variable name="out3" select="md2doc:build-HTML($out2)"/>
        <xsl:copy-of select="$out2"/>
<!--        <xsl:copy-of select="md2doc:build-HTML($out2)"/>-->
<!--        <xsl:copy-of select="md2doc:do-block($raw-xml)"/>-->
<!--        <xsl:apply-templates select="$out2"/>-->
        <xsl:result-document href="../test/out/output-functions.xml" method="xml">
            
                <xsl:copy-of select="$out3"/>
                  
        </xsl:result-document>
        
    </xsl:template>
      
    <xsl:function name="md2doc:alert">
        <xsl:param name="number" as="xs:integer"/>
        <xsl:param name="type" as="xs:string"/>
        <xsl:sequence select="$messages/message[@type=$type][@no=$number]/text()"/>
    </xsl:function>
    
    <xsl:function name="md2doc:prdik">
        <xsl:variable name="pom" as="element()*">
            <line>12</line>
            <line>cuzz1</line>
            <line>3</line>
            <line>cuzz</line>
        </xsl:variable>
        <xsl:for-each select="$pom">
            <xsl:variable name="element" select="." as="element()"/>
            <xsl:analyze-string select="." regex="^\d" >
                <xsl:matching-substring>
                    <xsl:element name="number">
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:copy-of select="$element"/>
                    <!--<xsl:element name="line">
                        <xsl:value-of select="."/>
                    </xsl:element>-->
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:variable name="regex">
        
        <block element="headlineX">^\n?(#+)(.+|[\r\n\t])$</block>
        <block element="headline1">^\n?(=+)$</block>
        <block element="headline2">^\n?(-+)$</block>
        <block element="horizontal-rule">^\n?(([\*-_]\s*){3,})$</block>
        <block element="unordered-list">^\n?\s{0,3}([\*\+-])\s(.+|[\r\n\t])$</block>
        <block element="ordered-list">^\n?\s{0,3}(\d+?)\.\s(.+|[\r\n\t])$</block>
        <block element="codeblock">^\n?(\s{4})(.+|[\r\n\t])$</block>
        <block element="blockquote">^\n?(>)\s(.+|[\r\n\t])$</block>
        
<!--        <block element="linebreak">^(\s{2,}\r)$</block>-->
<!--        <paragraph type="block">^()(.+|[\r\n\t])$</paragraph>-->
        <!--        <inline markup="anchor"></inline>-->
    </xsl:variable>
    
    <xsl:variable name="messages">
        <message type="error" no="1">Error with input file: incorrect encoding or missing file</message>
        <message type="error" no="2">Non matching: </message>
        <message type="error" no="3">Error</message>
    </xsl:variable>
    
    
    
    
    <xsl:function name="md2doc:parse-to-block">
        <xsl:param name="lines" as="xs:string*"/>
        <xsl:for-each select="$lines">
            <xsl:message>
                <xsl:text>INPUT text: </xsl:text><xsl:value-of select="."/>&LF;
            </xsl:message>
            <!--            <xsl:value-of select="replace(., '>', 'naslo to!')"/>  -->
            <!--            <xsl:value-of select="if (matches(., '&gt;')) then 'true' else 'false'"/> -->
            <xsl:sequence select="md2doc:match-block-regex(.,1)"/>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="md2doc:match-block-regex">
        <xsl:param name="text"/>
        <xsl:param name="regex-pos" as="xs:integer"/>
        <xsl:variable name="reg" as="xs:string" select="$regex/block[$regex-pos]/text()"/>
        <xsl:message>
            <xsl:text>(</xsl:text><xsl:value-of select="$regex-pos"/><xsl:text>)&#x20;</xsl:text>
            <xsl:value-of select="$reg"/>&LF;
        </xsl:message>
        <xsl:analyze-string select="$text" regex="{$reg}" flags="x">
            <xsl:matching-substring>
                <xsl:message>
                    <xsl:text>FOUND MATCH ! with regex: </xsl:text><xsl:value-of select="$reg"/>
                    <xsl:text> on position: (</xsl:text><xsl:value-of select="$regex-pos"/><xsl:text>)</xsl:text>&LF;
                    <xsl:value-of select="$text"/>&LF;
                </xsl:message>
                <xsl:element name="line">
                    <xsl:attribute name="element">
                        <xsl:value-of select="$regex/block[text()=$reg]/@element"/>
                    </xsl:attribute>
                    <xsl:attribute name="markdown">
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:attribute>
                    <xsl:value-of select="regex-group(2)"/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:choose>
                    <xsl:when test="$regex-pos + 1 &lt;= $regex//block/last()">
                        <xsl:sequence select="md2doc:match-block-regex($text,$regex-pos + 1)"/>
                        <xsl:message>
                            <xsl:text>Rekurze na regex: </xsl:text><xsl:value-of select="$regex-pos + 1"/>
                        </xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="line">
                            <xsl:attribute name="element">
                                <!--                                <xsl:value-of select="string('paragraph')"/>-->
                            </xsl:attribute>
                            <xsl:value-of select="replace($text, '\n+?', '')"/>
                        </xsl:element>
                        <xsl:message>                       
                            <xsl:text>NOT FOUND MATCH ! with regex: </xsl:text><xsl:value-of select="$reg"/>
                            <xsl:value-of select="$text"/>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
                <!--<xsl:sequence select="
                    if ($regex-pos + 1 &lt;= $regex//block/last()) 
                    then md2doc:match-block-regex($text,$regex-pos + 1) 
                    else $text"/>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>   
    </xsl:function>
    
</xsl:stylesheet>