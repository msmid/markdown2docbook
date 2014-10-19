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
                <xsl:value-of select="concat(unparsed-text($uri, $encoding),'&#xA;&#xA;')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:sequence select="md2doc:alert(1, 'error')"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="md2doc:unite-endlines">
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
    
    <xsl:function name="md2doc:parse-html">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(^&lt;(\w+)\b(.*\n)*?&lt;/\2&gt;[ \t]*(?=\n+))" flags="m!">
            <xsl:matching-substring>
                
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:run-block">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="result" select="md2doc:parse-headers($text)"/>
        <!--<xsl:variable name="bqList" select="md2doc:parse-lists($bq)"/>-->
        <xsl:copy-of select="$result"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-headers">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--setext style-->
        <xsl:analyze-string select="$text" 
            regex="(^(.+)[ \t]*\n(=+)[ \t]*$)|(^(.+)[ \t]*\n(-+)[ \t]*$)" flags="m">
<!--            (^(.+)[ \t]*\n(=+)[ \t]*\n+)|(^(.+)[ \t]*\n(-+)[ \t]*\n+)-->
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(.,'=')">
                        <h1><xsl:copy-of select="regex-group(2)"/></h1>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2><xsl:copy-of select="regex-group(5)"/></h2>
                    </xsl:otherwise>
                </xsl:choose>         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--atx style-->
                <xsl:analyze-string select="." regex="^(#{{1,6}})[ \t]*(.+?)[ \t]*#*$" flags="m">
<!--                    ^(#{{1,6}})[ \t]*(.+?)[ \t]*#*\n+ -->
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
<!--                <xsl:copy-of select="md2doc:parse-lists(.)"/>-->
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
<!--                        <xsl:copy-of select="."/>-->
<!--                        <xsl:copy-of select="normalize-space(.)"/>-->
                    </code>
                </pre>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
<!--                <xsl:copy-of select="."/>-->
                <xsl:copy-of select="md2doc:parse-lists(.)"/>
<!--                <xsl:copy-of select="md2doc:parse-blockquotes(.)"/>-->
                <!--<xsl:message>
                    <xsl:value-of select="concat('codeblock-nonmatching:', .)"/>
                </xsl:message>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-lists">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="((^([ ]{{0,3}})([*+-]|\d+[.])[ \t]+)(.+\n)*\n*( .+\n*)*)+" flags="m">
            <xsl:matching-substring>
                <xsl:element name="{if (matches(regex-group(4),'[*+-]')) then 'ul' else 'ol'}">
                    <xsl:copy-of select="md2doc:parse-list-items(., string-length(regex-group(3)))"/>
                </xsl:element>
                <!--debug-->
                <obsahListu>&LF;<xsl:copy-of select="."/></obsahListu>
                <indent><xsl:copy-of select="string-length(regex-group(3))"/></indent>               
                <!--OLD: <list><xsl:copy-of select="md2doc:parse-list-items(replace(.,'\n+$',''))"/></list>-->             
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-blockquotes(.)"/>
<!--                <xsl:copy-of select="md2doc:parse-codeblocks(.)"/>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-list-items">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="indent" as="xs:integer"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="^\n?( {{{$indent}}})([*+-]|\d+[.]) (.+\n?)" flags="m">
            <xsl:matching-substring>
                <li><xsl:copy-of select="md2doc:run-block(regex-group(3))"/></li>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:choose>
                    <xsl:when test="$indent != 0">
                        <xsl:variable name="trim" select="concat('^ {', $indent, '}')" as="xs:string"/>
                        <xsl:copy-of select="md2doc:parse-lists(replace(., $trim,'','m'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="md2doc:parse-lists(.)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
        <!-- <xsl:analyze-string select="$text" 
            regex="(^([ ]{{0,{$indent}}})([*+-]|\d+[.])[ \t]+)((.+\n)\n*( .+\n*)*)" flags="m">
<!-\-            ^\n?( {{{$indent}}})([*+-]|\d+[.]) (.+\n?)
            (^([ ]{{0,{$indent}}})([*+-]|\d+[.])[ \t]+)((.+\n)\n*( .+\n*)*) -\->
            <xsl:matching-substring>
                <!-\-tady očekovat vnořený elementy, run-block
                EDIT: jeste je potreba udelat kdy se obsah li obali <p> a 8spaces codeblock-\->
                <!-\-<li><xsl:copy-of select="normalize-space(regex-group(2))"/></li>-\->
                <li><xsl:copy-of select="md2doc:run-block(regex-group(4))"/></li>
                <!-\-<xsl:message>
                    <xsl:value-of select="normalize-space(regex-group(2))"/>
                </xsl:message>-\->
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!-\-items that aren't intended same as first item, are considered as inner lists.
                    All we need is to trim their leading spaces based on intend of first item-\->
                <xsl:choose>
                    <!-\-Special case when list is intended. Regex is not allowed to match zero-legth eg. indent = 0-\->
                    <xsl:when test="$indent != 0">
                        <xsl:variable name="trim" select="concat('^ {', $indent, '}')" as="xs:string"/>
                        <xsl:copy-of select="md2doc:parse-lists(replace(., $trim,'','m'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-\-but I still want to parse nested lists-\->
                        <xsl:copy-of select="md2doc:parse-lists(.)"/>
                        <!-\-<xsl:message>
                            <xsl:value-of select="."/>
                        </xsl:message>-\->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:non-matching-substring>
        </xsl:analyze-string>-->
<!--        <xsl:copy-of select="$text"/>-->
<!--        <obsah><xsl:copy-of select="$text"/></obsah>-->
        <!--<xsl:message>
            <xsl:value-of select="$text"/>
        </xsl:message>-->
    </xsl:function>
    
    <xsl:function name="md2doc:parse-blockquotes">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(^[ \t]*&gt;[ \t]?.+\n(.+\n)*\n*)+" flags="m">
            <xsl:matching-substring>
                <blockquote>
                    <!--TODO: trim whitespace lines-->
                    <xsl:copy-of select="md2doc:run-block(replace(.,'^[ \t]*&gt; ?','','m'))"/>
<!--                    <obsah><xsl:copy-of select="replace(.,'^[ \t]*&gt; ?','','m')"/></obsah>-->
                    <!--<xsl:message>
                        <xsl:value-of select="."/>
                    </xsl:message>-->
                </blockquote>
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
        <xsl:variable name="split" select="tokenize(replace(replace($text,'^\n',''),'\n+$',''),'\n{2,}')"/>
        <xsl:for-each select="$split">
            <p><xsl:copy-of select="replace(replace(.,'^\n',''),'\n+$','')"/></p>
        </xsl:for-each>

       <!-- <xsl:analyze-string select="$text" regex="^(.+)\n*(.+)\n+" flags="m">
            <xsl:matching-substring>
<!-\-                <p><xsl:copy-of select="."/></p>-\->
<!-\-                <p><xsl:copy-of select="normalize-space(.)"/></p>-\->
                <p><xsl:copy-of select="replace(replace(.,'^\n',''),'\n+$','')"/></p>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>-->
    </xsl:function>
    
    <!--OTHER FUNCTIONS-->
    
    <xsl:function name="md2doc:system-info">
        <p>
            Version:
            <xsl:value-of select="system-property('xsl:version')" />
            <br />
            Vendor:
            <xsl:value-of select="system-property('xsl:vendor')" />
            <br />
            Vendor URL:
            <xsl:value-of select="system-property('xsl:vendor-url')" />
        </p>
    </xsl:function>
    
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