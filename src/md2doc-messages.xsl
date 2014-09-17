<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:md2doc="http://allwe.cz/ns/markdown2docbook"
    exclude-result-prefixes="xs md2doc"
    version="2.0">
    
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