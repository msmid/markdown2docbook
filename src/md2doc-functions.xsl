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
    
    <!--INITIATION FUNCTIONS-->
    
    <!-- Function that validates input file -->
    <xsl:function name="md2doc:load-input">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:param name="encoding" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="unparsed-text-available($uri, $encoding)">
                <xsl:value-of select="unparsed-text($uri, $encoding)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(1, 'error')"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="md2doc:unity-endline">
        <xsl:param name="text" as="xs:string"/>
        <xsl:value-of select="replace(replace($text,'\r\n','&#xA;'), '\r', '&#xA;')"/>
        <!--<xsl:analyze-string select="$text" regex="^[ \t]+\r?$">
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>-->
    </xsl:function>
    
    <xsl:function name="md2doc:strip-blanklines">
        <xsl:param name="text" as="xs:string"/>
        <xsl:analyze-string select="$text" regex="^[ \t]+?$" flags="m">
            <xsl:matching-substring/>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--PARSING FUNCTIONS-->
    
    <xsl:function name="md2doc:run-block">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="result" select="md2doc:parse-headers(concat($text,'&#xA;&#xA;'))"/>
        <!--<xsl:variable name="bqList" select="md2doc:parse-lists($bq)"/>-->
        <xsl:copy-of select="$result"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-headers">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--setext style-->
        <xsl:analyze-string select="$text" regex="(^(.+)[ \t]*\n(=+)[ \t]*\n+)|(^(.+)[ \t]*\n(-+)[ \t]*\n+)" flags="m">
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(.,'=')">
                        <h1><xsl:copy-of select="replace(replace(.,'=',''), '\n','')"/></h1>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2><xsl:copy-of select="replace(replace(.,'-',''), '\n','')"/></h2>
                    </xsl:otherwise>
                </xsl:choose>         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--atx style-->
                <xsl:analyze-string select="." regex="^(#{{1,6}})[ \t]*(.+?)[ \t]*#*\n+" flags="m">
                    <xsl:matching-substring>
                        <xsl:element name="h{string-length(regex-group(1))}">
                            <xsl:copy-of select="regex-group(2)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="md2doc:parse-rulers(.)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>         
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-rulers">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="^[ ]{{0,2}}([ ]?(\*|-|_)[ ]?){{3,}}[ \t]*$" flags="m">
            <xsl:matching-substring>
                <hr />
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-codeblocks(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-codeblocks">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(\n\n)((^([ ]{{4}}|\t).*\n+)+)" flags="m">
            <xsl:matching-substring>
                <pre>
                    <code>
                        <xsl:copy-of select="replace(replace(.,'^\n',''),'\n+$','')"/>
                        <!--<xsl:copy-of select="normalize-space(.)"/>-->
                    </code>
                </pre>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-lists(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-lists">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="((^[ ]{{0,3}}([*+-]|\d+[.])[ \t]+)(.+\n)*\n*( .+\n*)*)+" flags="m">
            <xsl:matching-substring>
                <list><xsl:copy-of select="."/></list>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-blockquotes(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-blockquotes">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(^[ \t]*&gt;[ \t]?.+\n(.+\n)*\n*)+" flags="m">
            <xsl:matching-substring>
                <blockquote>&LF;
                    <xsl:variable name="result">
                        <xsl:analyze-string select="." regex="^[ \t]*&gt;" flags="m">
                            <xsl:matching-substring/>
                            <xsl:non-matching-substring>
                                <xsl:copy-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <!--TODO: trim whitespace lines-->
                    <xsl:copy-of select="md2doc:parse-blockquotes($result)"/>
                    <!--<xsl:message>
                        <xsl:value-of select="$result"/>
                    </xsl:message>-->
                </blockquote>&LF;
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-paragraphs(.)"/>
                <!--<xsl:message>
                    <xsl:value-of select="."/>
                </xsl:message>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-paragraphs">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="^(.+)\n*(.+)\n?" flags="m">
            <xsl:matching-substring>
                <p><xsl:copy-of select="replace(replace(.,'^\n',''),'\n+$','')"/></p>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--OTHER FUNCTIONS-->
    
    <xsl:function name="md2doc:alert">
        <xsl:param name="number" as="xs:integer"/>
        <xsl:param name="type" as="xs:string"/>
        <xsl:sequence select="$messages/message[@type=$type][@no=$number]/text()"/>
    </xsl:function>
    
    <xsl:variable name="messages">
        <message type="error" no="1">Error with input file: incorrect encoding or missing file</message>
        <message type="error" no="2">Non matching: </message>
        
    </xsl:variable>
    
</xsl:stylesheet>