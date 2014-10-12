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

    <xsl:character-map name="map">
        
    </xsl:character-map>

    <!--Parameters for input text file NOTE: přidej required-->
    <xsl:param name="uri" as="xs:anyURI"/>
    <xsl:param name="encoding" as="xs:string" select="string('UTF-8')"/>
    <xsl:param name="topLevelTag" as="xs:string"/>

    <!--PHASE ONE-->
    <!--Step one; load input markdown document-->
    <xsl:variable name="input" select="md2doc:load-input('../test/in/test.md','utf-8')"/>
 
    <!--Co musím udělat než začnu parsovat?
    
        normalizovat line endings
        ošetřit HTML
        escapovany znaky
        link/image reference
        
        parsovani samotny:
        1. blocky
        2. inliny
    
    -->
 
    <!--PHASE TWO-->
    
    <!--Volani templatu na predelani myho xml na html a pote docbook-->



    <!--Main template to be called at the start of transformation-->
    <xsl:template name="main">
        
        <!--OUTPUT PHASE-->
        <xsl:result-document href="../test/out/output2.xml" format="docbook">&LF;

        </xsl:result-document>
        <xsl:result-document href="../test/out/output3.xml" format="docbook">&LF;
            <xsl:copy-of select="md2doc:parse-blockquote($input)"/>
        </xsl:result-document>
        <xsl:result-document href="../test/out/output.xml" format="docbook">&LF;
            
            <xsl:fallback>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(3, error)"/>
                </xsl:message>
            </xsl:fallback>
            
        </xsl:result-document>
        
    </xsl:template>
    
 <!--MARKDOWN REGEX-->
 
<!-- codespan (`+)(.+?)(?<!`)\1(?!`) -->
<!-- codeblock (?:\n\n|\A)((?:(?:[ ]{$g_tab_width} | \t).*\n+)+)((?=^[ ]{0,$g_tab_width}\S)|\Z) -->
<!-- blockquotes (^[ \t]*>[ \t]?.+\n(.+\n)*\n*)+ -->

</xsl:transform>
