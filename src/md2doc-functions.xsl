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
                <!--It is better when document ends with 2 newlines-->
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
    
    <xsl:function name="md2doc:run-block">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="result" select="md2doc:parse-block-html($text)"/>
        <xsl:copy-of select="$result"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-block-html">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="html-tags" 
            select="string('article|aside|body|blockquote|button|canvas|div|dl|embed|fieldset|footer|form|h[1-6]|header|map|object|ol|p|pre|section|table|ul|video|script|noscript|iframe|math|ins|del|')"/>
        <!--Start with comments-->
        <xsl:analyze-string select="$text" 
            regex="(?&lt;=\n\n)([ ]{{0,3}}(&lt;!(-\-.*?-\-\s*)+&gt;)[ \t]*(?=\n{{2,}}))" flags="m!">
            <xsl:matching-substring>
                <html><xsl:value-of select="." disable-output-escaping="yes"/></html>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Then proceed on html block elements-->
                <xsl:analyze-string select="." 
                    regex="(^[ ]{{0,3}}&lt;({$html-tags})\b(.*\n)*?.*&lt;/\2&gt;[ \t]*(?=\n+))" flags="m!">
                    <xsl:matching-substring>
                        <html><xsl:value-of select="." disable-output-escaping="yes"/></html>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <!--Dont forget on <hr />-->
                        <xsl:analyze-string select="." 
                            regex="(?&lt;=\n\n)([ ]{{0,3}}&lt;(hr)\b([^&lt;&gt;])*?/?&gt;[ \t]*(?=\n{{2,}}))" flags="m!">
                            <xsl:matching-substring>
                                <hr />
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:copy-of select="md2doc:parse-headers(.)"/> 
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-headers">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--setext style-->
        <xsl:analyze-string select="$text" 
            regex="(^(.+)[ \t]*\n(=+)[ \t]*\n+)|(^(.+)[ \t]*\n(-+)[ \t]*\n+)" flags="m">
<!--            (^(.+)[ \t]*\n(=+)[ \t]*$)|(^(.+)[ \t]*\n(-+)[ \t]*$)-->
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(.,'=')">
                        <h1><xsl:copy-of select="normalize-space(regex-group(2))"/></h1>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2><xsl:copy-of select="normalize-space(regex-group(5))"/></h2>
                    </xsl:otherwise>
                </xsl:choose>         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--atx style-->
                <xsl:analyze-string select="." regex="^(#{{1,6}})[ \t]*(.+)[ \t]*#*\n*" flags="m">
<!--                    ^(#{{1,6}})[ \t]*(.+?)[ \t]*#*$ -->
                    <xsl:matching-substring>
                        <xsl:element name="h{string-length(regex-group(1))}">
                            <xsl:copy-of select="normalize-space(regex-group(2))"/>
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
                <xsl:copy-of select="md2doc:parse-lists(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-lists">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" 
            regex="((^([ ]{{0,3}})([*+-]|\d+[.])[ \t]+)(.+\n)*\n*( .+\n*)*)+" flags="m">
            <xsl:matching-substring>
                <xsl:variable name="indent">
                    <xsl:analyze-string select="." regex="(^ {{0,3}}).+">
                        <xsl:matching-substring>
                            <xsl:copy-of select="string-length(regex-group(1))"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:element name="{if (matches(.,'^ *[*+-]')) then 'ul' else 'ol'}">
                    <xsl:copy-of select="md2doc:parse-list-items(., $indent)"/>
                </xsl:element>
                <!--debug-->
                <!--<obsahListu>&LF;<xsl:copy-of select="."/></obsahListu>
                <indent><xsl:copy-of select="$indent"/></indent> -->                         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--                <xsl:copy-of select="md2doc:parse-blockquotes(concat(., '&#xA;&#xA;'))"/>-->
                    <xsl:copy-of select="md2doc:parse-codeblocks(.)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-list-items">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="indent" as="xs:integer"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" 
            regex="(^ {{{$indent}}}([*+-]|\d+[.])[ \t]+)(.*\n*)((?! {{{$indent}}}([*+-]|\d+[.]))(.*\n*))*" flags="m!">
            <xsl:matching-substring>
                <li>
                    <xsl:variable name="stripList" select="replace(., concat('^ {', $indent, '}','(([*+-]|\d+[.]) +)'),'','m')"/>
                    <xsl:variable name="trim" select="
                        if ($indent != 0) 
                        then replace($stripList, concat('^ {', $indent, '}'),'','m') 
                        else $stripList"/>
                    <xsl:variable name="chop">
                        <xsl:analyze-string select="$stripList" regex="^ *([*+-]|\d+\.)" flags="m!">
                            <xsl:matching-substring>
                                <xsl:copy-of select="
                                    if ($indent != 0) 
                                    then replace(., concat('^ {', $indent, '}'),'','m') 
                                    else ."/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:copy-of select="replace(.,'^ {1,4}','','m')"/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:copy-of select="md2doc:run-block($chop)"/>
<!--                    <li-obsah><xsl:copy-of select="."/></li-obsah>-->
                </li>
                <!--<xsl:choose>
                    <xsl:when test="$indent != 0">
                        <xsl:variable name="trim" select="concat('^ {', $indent, '}')" as="xs:string"/>
                        <li><xsl:copy-of select="md2doc:run-block(replace(., concat($trim,'(([*+-]|\d+[.]) )?'),'','m'))"/></li>
                    </xsl:when>
                    <xsl:otherwise>
                        <li><xsl:copy-of select="md2doc:run-block(replace(., '^([*+-]|\d+[.]) ','','m'))"/></li>
                    </xsl:otherwise>
                </xsl:choose>-->
<!--                <li><xsl:copy-of select="md2doc:run-block(replace(., $trim,'','m'))"/></li>-->
<!--                                <LI-OBSAH><xsl:copy-of select="."/></LI-OBSAH>-->
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--here is dead end-->
                <deadEndListu><xsl:copy-of select="md2doc:run-block(replace(., '^(([*+-]|\d+[.]) )','','m'))"/></deadEndListu>
<!--                <xsl:copy-of select="md2doc:run-block(.)"/>-->
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
<!--                        <xsl:copy-of select="replace(replace(.,'^\n',''),'\n+$','')"/>-->
                        <xsl:copy-of select="replace(.,'^\n+ {4}','')"/>
<!--                        <xsl:copy-of select="normalize-space(.)"/>-->
                    </code>
                </pre>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-blockquotes(.)"/>
<!--                <neCode><xsl:copy-of select="concat('&#xA;',.)"/></neCode>-->
                <!--<xsl:message>
                    <xsl:value-of select="concat('codeblock-nonmatching:', .)"/>
                </xsl:message>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
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
        <!--<xsl:choose>
            <xsl:when test="matches($text,'(\n{2,})','m')">
                <xsl:for-each select="$split">
<!-\-                    <p><xsl:copy-of select="replace(.,' +$','')"/></p>-\->
                    <p><xsl:copy-of select="normalize-space(.)"/></p>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <bez><xsl:copy-of select="normalize-space($text)"/></bez>
<!-\-                <xsl:copy-of select="replace(replace($text,'^\n',''),'\n+$','')"/>-\->
            </xsl:otherwise>
        </xsl:choose>-->
        <xsl:for-each select="$split">
            <p><xsl:copy-of select="replace(replace(.,'^ +',''),' +$','')"/></p>
        </xsl:for-each>
<!--        <paraObsah><xsl:copy-of select="$text"/></paraObsah>-->
    </xsl:function>
    
    <xsl:function name="md2doc:parse-inline">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:copy-of select="md2doc:parse-codespans($text)"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-codespans">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="regex">
            <xsl:matching-substring>
                
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-images">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="regex">
            <xsl:matching-substring>
                
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-anchors">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="regex">
            <xsl:matching-substring>
                
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-strong">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="regex">
            <xsl:matching-substring>
                
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-emphasis">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="regex">
            <xsl:matching-substring>
                
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                
            </xsl:non-matching-substring>
        </xsl:analyze-string>
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