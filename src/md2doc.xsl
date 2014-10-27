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
    <xsl:output name="html" encoding="UTF-8" doctype-system="http://www.w3.org/TR/html4/strict.dtd"
        doctype-public="-//W3C//DTD HTML 4.01//EN"/>

    <xsl:character-map name="map">
        <xsl:output-character character="\" string=""/>
    </xsl:character-map>

    <!--Parameters for input text file NOTE: přidej required-->
    <xsl:param name="uri" as="xs:string"/>
    <xsl:param name="encoding" as="xs:string" select="string('UTF-8')"/>
    <!--jako root muze bejt acknowledgements, appendix, article, bibliography, book, chapter, colophon, 
    dedication, glossary, index, para, part, preface, refentry, reference, refsect1, refsect2, refsect3, 
    refsection, sect1, sect2, sect3, sect4, sect5, section, set, setindex, and toc.-->
    <xsl:param name="rootTag" as="xs:string" select="'book'"/>
    <xsl:param name="docBooktemplate" as="xs:string"/>
    <xsl:param name="outputMethod"/>

    <!--Main template to be called at the start of transformation-->
    <xsl:template name="main">
        
        <!--OUTPUT PHASE-->
        <xsl:result-document href="../test/out/output3.xml" format="docbook">&LF;
<!--            <xsl:copy-of select="md2doc:system-info()"/>-->
            
<!--            <xsl:copy-of select="md2doc:run-block($text-stripped)"/>-->
            <xsl:variable name="i">
&lt;div ahoj="a"&gt;as
    &lt;div ahoj="a"&gt;as&lt;/div&gt;
&lt;/div&gt;
</xsl:variable>
            <!--<xsl:variable name="test" select="tokenize($i,'\n([*+-]|\d+\.)', 'm!')"/>
            <xsl:for-each select="$test">
                <token><xsl:copy-of select="."/></token>
            </xsl:for-each>
            <trim><xsl:copy-of select="replace(replace($i,'^\n+',''),'\n+$','')"/></trim>-->
            <xsl:analyze-string select="$i" 
                regex="(^&lt;(div)\b(.*\n)*?&lt;/\2&gt;[ \t]*(?=\n+|\Z))" flags="m!">
                <xsl:matching-substring>
                    <gr1><xsl:value-of select="regex-group(1)"/></gr1>
                    <gr2><xsl:value-of select="regex-group(2)"/></gr2>
                    <gr3><xsl:value-of select="regex-group(3)"/></gr3>
                    <gr4><xsl:value-of select="regex-group(4)"/></gr4>
                    <gr5><xsl:value-of select="regex-group(5)"/></gr5>
                    <gr6><xsl:value-of select="regex-group(6)"/></gr6>
                    <match><xsl:value-of select="."/></match>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <non><xsl:value-of select="."/></non>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:result-document>
        
        <xsl:result-document href="../test/out/output2.xml" format="docbook">&LF;
           
<!--            <xsl:copy-of select="md2doc:main('../test/in/test2.md','utf-8')"/>-->
            <xsl:variable name="parse" select="md2doc:main('../test/in/test-frag.md','utf-8')"/>
            <xsl:variable name="html">
                <root>
                    <xsl:sequence select="$parse"/>
                </root>
            </xsl:variable>
            <xsl:sequence select="md2doc:transform-to-doc($html)"/>
            
        </xsl:result-document>
        <xsl:result-document href="../test/out/output.xml" format="docbook">&LF;
            <!--<xsl:variable name="input" select="md2doc:load-input('../test/in/test-frag.md','utf-8')"/>
            <xsl:variable name="text-united" select="md2doc:unite-endlines($input)"/>
            <xsl:variable name="text-stripped-blanklines" select="md2doc:strip-blanklines($text-united)"/>

            <xsl:copy-of select="md2doc:run-block($text-stripped-blanklines)"/>-->
            
            <xsl:copy-of select="md2doc:main('../test/in/test-frag.md','utf-8')"/>
            
            <xsl:fallback>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(3, error)"/>
                </xsl:message>
            </xsl:fallback>
            
        </xsl:result-document>
        
    </xsl:template>
    
    <xsl:template match="/" mode="transform">
        <xsl:element name="{$rootTag}">
<!--            <xsl:attribute name="version" select="5"/>-->
            <xsl:apply-templates select="*" mode="transform"/> 
        </xsl:element>                    
        
    </xsl:template>
    
    <xsl:template match="root" mode="transform">
        <xsl:apply-templates select="node()|@*" mode="transform"/>
    </xsl:template>
    
    <xsl:template match="html" mode="transform">
        <xsl:value-of select="text()" disable-output-escaping="yes"/>
    </xsl:template>
    
    <xsl:template match="p" mode="transform">
        <para>
            <xsl:apply-templates select="node()|@*"/>
        </para>
    </xsl:template>
    
<!--    <xsl:template match="h1|h2" mode="transform">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="ul|li" mode="transform">
        <xsl:copy-of select="."/>
    </xsl:template>-->
    
    <xsl:template match="node()|@*" name="identity" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:transform>
