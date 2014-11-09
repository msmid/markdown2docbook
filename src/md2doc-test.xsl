<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY LF "<xsl:text>&#xA;</xsl:text>">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"
    xmlns:sax="http://saxon.sf.net/"
    exclude-result-prefixes="xs md2doc sax"
    version="2.0">
    
    <!--<xsl:import href="md2doc-functions.xsl"/>-->
    
    <xsl:template name="main-from-file">
        
        <!--        <xsl:copy-of select="md2doc:parse-codespans('text **tucne `kod` tucne** konec ***`ada`*** vety.','')"/>-->
        
        <xsl:result-document href="../test/out/output3.xml" format="docbook">&LF;
            <xsl:variable name="input" select="md2doc:read-file('../test/in/test-frag.md','utf-8')"/>
            
            <!--takovyhle template aby slo to html-->
            <xsl:variable name="html">
                <xsl:sequence select="md2doc:get-html($input)"/>
            </xsl:variable>
            
            <xsl:sequence select="md2doc:transform-to-doc($html, '', '')"/>
            
            
        </xsl:result-document>
        
        <xsl:result-document href="../test/out/output2.xml" format="docbook">&LF;
            
            <xsl:variable name="input" select="md2doc:read-file('../test/in/test2.md','utf-8')"/>
            <xsl:sequence select="md2doc:convert($input, '', 'article')"/>
            <xsl:sequence select="md2doc:get-processor-info()"/>
            
        </xsl:result-document>
        
        <xsl:result-document href="../test/out/output.xml" format="docbook">&LF;
            <xsl:variable name="input" select="md2doc:read-file('../test/in/test-frag.md','utf-8')"/>
            
            <!--            <xsl:copy-of select="md2doc:run-block($text-stripped-blanklines)"/>-->
            
            <xsl:sequence select="md2doc:get-html($input)"/>
            <!--            <xsl:copy-of select="md2doc:convert($input)"/>-->
            <!--            <xsl:copy-of select="md2doc:system-info()"/>-->
            <xsl:fallback>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(3, error)"/>
                </xsl:message>
            </xsl:fallback>
            
        </xsl:result-document>
        
    </xsl:template>
    
    <xsl:template name="main-with-html">
        <xsl:result-document href="../test/out/out-html.xml" format="html">&LF;
            <xsl:variable name="input" select="md2doc:read-file('../test/in/test-frag.md','utf-8')"/>
            
            <xsl:variable name="html">
                <xsl:sequence select="md2doc:get-html($input)"/>
            </xsl:variable>
            
            <xsl:sequence select="md2doc:transform-to-doc($html, $headline-element,'')"/>
            
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="main-xml">
        
    </xsl:template>
    
    <xsl:template name="main-from-string">
        <xsl:sequence select="md2doc:convert($input-string, $headline-element,'')"/>
        
    </xsl:template>
    
</xsl:stylesheet>