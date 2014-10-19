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
    <xsl:variable name="input" select="md2doc:load-input('../test/in/test2.md','utf-8')"/>
    <xsl:variable name="text-united" select="md2doc:unite-endlines($input)"/>
    <xsl:variable name="text-stripped" select="md2doc:strip-blanklines($text-united)"/>
    <!--Co musím udělat než začnu parsovat?
        
        stripnout radky kde jsou jen spaces/tabs
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
        <xsl:result-document href="../test/out/output3.xml" format="docbook">&LF;
<!--            <xsl:copy-of select="md2doc:system-info()"/>-->
            
<!--            <xsl:copy-of select="md2doc:run-block($text-stripped)"/>-->
            
            <xsl:if test="matches('prvni radek
                
                druhy radek
                
                treti radek','prvni', 'm')">ano</xsl:if>

            <!--&LF;<xsl:text>HEADERS</xsl:text>&LF;
            <xsl:copy-of select="md2doc:parse-headers($text-stripped)"/>
            &LF;<xsl:text>RULERS</xsl:text>&LF;
            <xsl:copy-of select="md2doc:parse-rulers($text-stripped)"/>
            &LF;<xsl:text>CODEBLOCKS</xsl:text>&LF;
            <xsl:copy-of select="md2doc:parse-codeblocks($text-stripped)"/>
            &LF;<xsl:text>LISTS</xsl:text>&LF;
            <xsl:copy-of select="md2doc:parse-lists($text-stripped)"/>
            &LF;<xsl:text>BLOCKQUOTES</xsl:text>&LF;
            <xsl:copy-of select="md2doc:parse-blockquotes($text-stripped)"/>
            &LF;<xsl:text>PARAGRAPHS</xsl:text>&LF;
            <xsl:copy-of select="md2doc:parse-paragraphs($text-stripped)"/>-->
        </xsl:result-document>
        <xsl:result-document href="../test/out/output2.xml" format="docbook">&LF;
           
            <xsl:copy-of select="md2doc:run-block($text-stripped)"/>
            
        </xsl:result-document>
        <xsl:result-document href="../test/out/output.xml" format="docbook">&LF;
            <xsl:variable name="input" select="md2doc:load-input('../test/in/test-frag.md','utf-8')"/>
            <xsl:variable name="text-united" select="md2doc:unite-endlines($input)"/>
            <xsl:variable name="text-stripped" select="md2doc:strip-blanklines($text-united)"/>
            <xsl:copy-of select="md2doc:run-block($text-stripped)"/>
            
            <xsl:fallback>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(3, error)"/>
                </xsl:message>
            </xsl:fallback>
            
        </xsl:result-document>
        
    </xsl:template>
    
<!--MARKDOWN REGEX-->

<!-- nested brackets (?>[^\[\]]+|\[(??{ $g_nested_brackets })\])* -->

<!-- codespan (`+)(.+?)(?<!`)\1(?!`) -->
<!-- codeblock (?:\n\n|\A)((?:(?:[ ]{$g_tab_width} | \t).*\n+)+)((?=^[ ]{0,$g_tab_width}\S)|\Z) -->
<!-- blockquotes (^[ \t]*>[ \t]?.+\n(.+\n)*\n*)+ -->
<!-- strip link definitions ^[ ]{0,3}\[(.+)\]:[ \t]*\n?[ \t]*<?(\S+?)>?[ \t]*\n?[ \t]*(?:(?<=\s)["(](.+?)[")][ \t]*)?(?:\n+|\Z)
                                                                                         (?<=\s) lookbehind není supportovaný    -->
<!-- html tags 1 (^<($block_tags_a)\b(.*\n)*?</\2>[ \t]*(?=\n+|\Z)) -->
<!-- html tegs liberally 2 (^<($block_tags_b)\b(.*\n)*?.*</\2>[ \t]*(?=\n+|\Z)) -->
<!-- html special case <hr /> (?:(?<=\n\n)|\A\n?)([ ]{0,3}<(hr)\b([^<>])*?/?>[ \t]*(?=\n{2,}|\Z)) 
                                 lookbehind, nefaká bez něj-->
<!-- html special case comment (?:(?<=\n\n)|\A\n?)([ ]{0,3}(?s:<!(-\-.*?-\-\s*)+>)[ \t]*(?=\n{2,}|\Z)) 
                                  lookbehind, nefaká bez něj-->
<!-- horizontal rule * ^[ ]{0,2}([ ]?\*[ ]?){3,}[ \t]*$ -->
<!-- horizontal rule - ^[ ]{0,2}([ ]?-[ ]?){3,}[ \t]*$ -->
<!-- horizontal rule _ ^[ ]{0,2}([ ]?_[ ]?){3,}[ \t]*$ -->
<!-- a reference-style (\[($g_nested_brackets)\][ ]?(?:\n[ ]*)?\[(.*?)\]) -->
<!-- a inline-style (\[($g_nested_brackets)\]\([ \t]*<?(.*?)>?[ \t]*((['"])(.*?)\5)?\)) -->
<!-- images reference-style (!\[(.*?)\][ ]?(?:\n[ ]*)?\[(.*?)\]) -->
<!-- image inline-style (!\[(.*?)\]\([ \t]*<?(\S+?)>?[ \t]*((['"])(.*?)\5[ \t]*)?\)) -->
<!-- whole list (([ ]{0,3}((?:[*+-]|\d+[.]))[ \t]+)(?s:.+?)(\z|\n{2,}(?=\S)(?![ \t]*(?:[*+-]|\d+[.])[ \t]+))) -->
<!-- list item (\n)?(^[ \t]*)($marker_any) [ \t]+((?s:.+?)(\n{1,2}))(?= \n* (\z | \2 ($marker_any) [ \t]+)) -->
<!-- header1 setext ^(.+)[ \t]*\n=+[ \t]*\n+ -->
<!-- header2 setext ^(.+)[ \t]*\n-+[ \t]*\n+ -->
<!-- header atx ^(\#{1,6})[ \t]*(.+?)[ \t]*\#*\n+ -->
</xsl:transform>
