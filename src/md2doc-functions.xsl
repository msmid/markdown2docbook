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
    
    <!--PARSING FUNCTIONS-->
    
    <xsl:function name="md2doc:parse-blockquote">
        <xsl:param name="text" as="xs:string"/>
        <!--        <xsl:copy-of select="$text"/>-->
        <xsl:if test="contains($text, '&#x0A;')">
            <!--<xsl:message>
                <xsl:value-of select="'ano'"/>
            </xsl:message>-->
        </xsl:if>
        <!--<xsl:analyze-string select="$text" regex="&#x0A;" flags="m">
            <xsl:matching-substring>
                <blockquote><xsl:value-of select="."/></blockquote>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>-->
        <xsl:analyze-string select="$text" regex="(^[ \t]*&gt;[ \t]?(.+)(.+\r?\n)*\r?\n*)+" flags="m">
            <xsl:matching-substring>
                <blockquote><xsl:value-of select="replace(.,'&gt;','')"/></blockquote>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <ne><xsl:value-of select="."/></ne>
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