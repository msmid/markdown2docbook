<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY LF "<xsl:text>&#xA;</xsl:text>">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:md2doc="http://allwe.cz/ns/markdown2docbook"
    exclude-result-prefixes="xs md2doc"
    version="2.0">
    
    <!--INITIATION FUNCTIONS-->
    
    <!-- Function that validates input file -->
    <xsl:function name="md2doc:read-file">
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
    
    <xsl:function name="md2doc:read-string">
        <xsl:param name="input" as="xs:string"/>
        
    </xsl:function>
    
    <xsl:function name="md2doc:unite-endlines">
        <xsl:param name="text" as="xs:string"/>
        
        <xsl:value-of select="replace(replace($text,'\r\n','&#xA;'), '\r', '&#xA;')"/>
    </xsl:function>
    
    <xsl:function name="md2doc:strip-blanklines">
        <xsl:param name="text" as="xs:string"/>
        
        <xsl:analyze-string select="$text" regex="^[ \t]+?$" flags="m">
            <xsl:matching-substring/>
            <xsl:non-matching-substring>
                <xsl:sequence select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:strip-references">
        <xsl:param name="input" as="xs:string*"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" 
            regex="^[ ]{{0,3}}\[(.+)\]:[ \t]*\n?[ \t]*&lt;?(\S+?)&gt;?[ \t]*\n?[ \t]*(?:(?&lt;=\s)[&quot;(](.+?)[&quot;)][ \t]*)?(?:\n+|\Z)" flags="m!">
            <xsl:matching-substring/>
            <xsl:non-matching-substring>
                <xsl:sequence select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:save-references">
        <xsl:param name="input" as="xs:string*"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <references>
            <xsl:analyze-string select="$text" 
                regex="^[ ]{{0,3}}\[(.+)\]:[ \t]*\n?[ \t]*&lt;?(\S+?)&gt;?[ \t]*\n?[ \t]*(?:(?&lt;=\s)[&quot;(](.+?)[&quot;)][ \t]*)?(?:\n+|\Z)" flags="m!">
                <xsl:matching-substring>
                    <xsl:element name="reference">
                        <xsl:attribute name="id" select="lower-case(regex-group(1))"/>
                        <xsl:attribute name="url" select="regex-group(2)"/>
                        <xsl:attribute name="title" select="regex-group(3)"/>
                    </xsl:element>
                </xsl:matching-substring>
                <xsl:non-matching-substring/>
            </xsl:analyze-string>
        </references>
    </xsl:function>
    
    <xsl:function name="md2doc:main">
        <xsl:param name="file" as="xs:string"/>
        <xsl:param name="encoding" as="xs:string"/>
        
        <xsl:variable name="input" select="md2doc:read-file($file, $encoding)"/>
        <xsl:variable name="text-united" select="md2doc:unite-endlines($input)"/>
        <xsl:variable name="text-stripped-blanklines" select="md2doc:strip-blanklines($text-united)"/>
        <xsl:variable name="text-stripped-refs" select="md2doc:strip-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="refs" select="md2doc:save-references($text-stripped-blanklines)"/>
        
        <xsl:sequence select="md2doc:run-block($text-stripped-refs, $refs)"/>
        
    </xsl:function>
    
    <!--PARSING FUNCTIONS-->
    
    <xsl:function name="md2doc:run-block">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="result" select="md2doc:parse-block-html($text, $refs)"/>
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-block-html">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="html-tags" 
            select="string('article|aside|body|blockquote|button|canvas|div|dl|embed|fieldset|footer|form|h[1-6]|header|map|nav|object|ol|p|pre|section|table|ul|video|script|noscript|iframe|math|ins|del|')"/>
        <!--Start with comments-->
        <xsl:analyze-string select="$text" 
            regex="(?&lt;=\n\n)([ ]{{0,3}}(&lt;!(-\-.*?-\-\s*)+&gt;)[ \t]*(?=\n{{2,}}))" flags="m!">
            <xsl:matching-substring>
                <html><xsl:value-of select="." disable-output-escaping="yes"/></html>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Then proceed on html block elements-->
                <xsl:analyze-string select="." 
                    regex="(^&lt;({$html-tags})\b(.*\n)*?&lt;/\2&gt;[ \t]*(?=\n+|\Z))" flags="m!">
                    <xsl:matching-substring>
                        <html><xsl:value-of select="." disable-output-escaping="yes"/></html>
                        <!--<xsl:element name="{regex-group(2)}">
                            <xsl:attribute name="atributy" select="regex-group(3)"/>
                            <xsl:copy-of select="md2doc:parse-block-html(regex-group(5))"/>
                        </xsl:element>-->
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="(^&lt;({$html-tags})\b(.*\n)*?.*&lt;/\2&gt;[ \t]*(?=\n+|\Z))" flags="m!">
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
                                        <xsl:copy-of select="md2doc:parse-headers(., $refs)"/> 
                                    </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>   
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-headers">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--setext style-->
        <xsl:analyze-string select="$text" 
            regex="(^(.+)[ \t]*\n(=+)[ \t]*\n+)|(^(.+)[ \t]*\n(-+)[ \t]*\n+)" flags="m">
<!--            (^(.+)[ \t]*\n(=+)[ \t]*$)|(^(.+)[ \t]*\n(-+)[ \t]*$)-->
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(.,'=')">
                        <md2doc:h1><xsl:copy-of select="md2doc:run-inline(normalize-space(regex-group(2)), $refs)"/></md2doc:h1>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2><xsl:copy-of select="md2doc:run-inline(normalize-space(regex-group(5)), $refs)"/></h2>
                    </xsl:otherwise>
                </xsl:choose>         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--atx style-->
                <xsl:analyze-string select="." regex="^(#{{1,6}})[ \t]*(.+)[ \t]*#*\n*" flags="m">
<!--                    ^(#{{1,6}})[ \t]*(.+?)[ \t]*#*$ -->
                    <xsl:matching-substring>
                        <xsl:element name="h{string-length(regex-group(1))}">
                            <xsl:copy-of select="md2doc:run-inline(normalize-space(regex-group(2)), $refs)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="md2doc:parse-rulers(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>         
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>   
    
    <xsl:function name="md2doc:parse-rulers">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--First rulers marked with *, then - and last _ -->
        <xsl:analyze-string select="$text" regex="^[ ]{{0,2}}([ ]?(\*)[ ]?){{3,}}[ \t]*$" flags="m">
            <xsl:matching-substring>
                <hr />
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:analyze-string select="." regex="^[ ]{{0,2}}([ ]?(-)[ ]?){{3,}}[ \t]*$" flags="m">
                    <xsl:matching-substring>
                        <hr />
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="^[ ]{{0,2}}([ ]?(_)[ ]?){{3,}}[ \t]*$" flags="m">
                            <xsl:matching-substring>
                                <hr />
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:copy-of select="md2doc:parse-lists(., $refs)"/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-lists">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" 
            regex="((^([ ]{{0,3}})([*+-]|\d+[.])[ \t]+)(.+\n)*\n*( .+\n*)*)+" flags="m">
            <xsl:matching-substring>
                <xsl:variable name="indent">
                    <xsl:analyze-string select="." regex="(^ {{0,3}}).+">
                        <xsl:matching-substring>
                            <xsl:sequence select="string-length(regex-group(1))"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:element name="{if (matches(.,'^ *[*+-]')) then 'ul' else 'ol'}">
                    <xsl:sequence select="md2doc:parse-list-items(., $indent, $refs)"/>
                </xsl:element>
                <!--debug-->
                <!--<obsahListu>&LF;<xsl:copy-of select="."/></obsahListu>
                <indent><xsl:copy-of select="$indent"/></indent> -->                         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--                <xsl:copy-of select="md2doc:parse-blockquotes(concat(., '&#xA;&#xA;'))"/>-->
                    <xsl:sequence select="md2doc:parse-codeblocks(., $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-list-items">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="indent" as="xs:integer"/>
        <xsl:param name="refs"/>
        
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
                                <xsl:value-of select="
                                    if ($indent != 0) 
                                    then replace(., concat('^ {', $indent, '}'),'','m') 
                                    else ."/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:copy-of select="replace(.,'^ {1,4}','','m')"/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:copy-of select="md2doc:run-block($chop, $refs)"/>
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
                <deadEndListu><xsl:copy-of select="md2doc:run-block(replace(., '^(([*+-]|\d+[.]) )','','m'), $refs)"/></deadEndListu>
<!--                <xsl:copy-of select="md2doc:run-block(.)"/>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-codeblocks">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
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
                <xsl:copy-of select="md2doc:parse-blockquotes(., $refs)"/>
<!--                <neCode><xsl:copy-of select="concat('&#xA;',.)"/></neCode>-->
                <!--<xsl:message>
                    <xsl:value-of select="concat('codeblock-nonmatching:', .)"/>
                </xsl:message>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-blockquotes">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(^[ \t]*&gt;[ \t]?.+\n(.+\n)*\n*)+" flags="m">
            <xsl:matching-substring>
                <blockquote>
                    <!--TODO: trim whitespace lines-->
                    <xsl:copy-of select="md2doc:run-block(replace(.,'^[ \t]*&gt; ?','','m'), $refs)"/>
<!--                    <obsah><xsl:copy-of select="replace(.,'^[ \t]*&gt; ?','','m')"/></obsah>-->
                    <!--<xsl:message>
                        <xsl:value-of select="."/>
                    </xsl:message>-->
                </blockquote>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-paragraphs(., $refs)"/>
                <!--<xsl:message>
                    <xsl:value-of select="."/>
                </xsl:message>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-paragraphs">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        
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
        <xsl:variable name="split" select="tokenize(replace(replace($text,'^\n',''),'\n+$',''),'\n{2,}')"/>
        <xsl:for-each select="$split">
            <p><xsl:copy-of select="md2doc:run-inline(replace(replace(.,'^ +',''),' +$',''), $refs)"/></p>
        </xsl:for-each>
<!--        <paraObsah><xsl:copy-of select="$text"/></paraObsah>-->
    </xsl:function>
    
    <xsl:function name="md2doc:run-inline">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--<xsl:copy-of select="md2doc:parse-codespans($text, $refs)"/>-->
<!--        <xsl:copy-of select="md2doc:parse-images($text, $refs)"/>-->
        <xsl:copy-of select="md2doc:parse-special-chars($text, $refs)"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-special-chars">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="chars" select="string('\\\\|\\`|\\\*|\\_|\\\{|\\\}|\\\[|\\\]|\\\(|\\\)|\\#|\\\+|\\-|\\\.|\\!')"/>
        <xsl:analyze-string select="$text" regex="{$chars}">
            <xsl:matching-substring>
                <xsl:value-of select="replace(.,'\\','')"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-strong(.,$refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-strong">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(\*\*|__)(?=\S)(.+?[*_]*)(?&lt;=\S)\1" flags="!">
            <xsl:matching-substring>
                <strong><xsl:copy-of select="md2doc:run-inline(regex-group(2), $refs)"/></strong>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-emphasis(., $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-emphasis">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(\*|_)(?=\S)(.+?)(?&lt;=\S)\1" flags="!">
            <xsl:matching-substring>
                <em><xsl:copy-of select="md2doc:run-inline(regex-group(2),$refs)"/></em>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--<xsl:value-of select="."/>-->
                <xsl:copy-of select="md2doc:parse-codespans(.,$refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-codespans">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(`+)(.+?)(?&lt;!`)\1(?!`)" flags="m!">
            <xsl:matching-substring>
                <code><xsl:copy-of select="normalize-space(regex-group(2))"/></code>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy-of select="md2doc:parse-images(., $refs)"/>
<!--                <xsl:copy-of select="md2doc:parse-special-chars(., $refs)"/>-->
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-images">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--Inline style images-->
        <xsl:analyze-string select="$text" 
            regex="(!\[(.*?)\]\([ \t]*&lt;?(\S+?)&gt;?[ \t]*(([&apos;&quot;])(.*?)\5[ \t]*)?\))" flags="">
            <xsl:matching-substring>
                <xsl:element name="img">
                    <xsl:attribute name="src" select="regex-group(3)"/>
                    <xsl:attribute name="alt" select="regex-group(2)"/>
                    <xsl:attribute name="title" select="regex-group(6)"/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Reference style-->
                <xsl:analyze-string select="." regex="(!\[(.*?)\][ ]?(?:\n[ ]*)?\[(.*?)\])" flags="!">
                    <xsl:matching-substring>
                        <xsl:variable name="id" select="lower-case(regex-group(3))"/>
                        <xsl:choose>
                            <xsl:when test="$refs/reference[@id = $id]">
                                <xsl:element name="img">
                                    <xsl:attribute name="src" select="$refs/reference[@id = $id]/@url"/>
                                    <xsl:attribute name="alt" select="regex-group(2)"/>
                                    <xsl:attribute name="title" select="$refs/reference[@id = $id]/@title"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="md2doc:parse-anchors(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
<!--        <xsl:copy-of select="$refs"/>-->
    </xsl:function>
    
    <xsl:function name="md2doc:parse-anchors">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--Inline style first-->
        <xsl:analyze-string select="$text" 
            regex="(\[(.*?)\]\([ \t]*&lt;?(.*?)&gt;?[ \t]*(([&apos;&quot;])(.*?)\5)?\))" flags="!">
            <xsl:matching-substring>
                <xsl:element name="a">
                    <xsl:attribute name="href" select="regex-group(3)"/>
                    <xsl:attribute name="title" select="regex-group(6)"/>
                    <xsl:copy-of select="md2doc:parse-strong(regex-group(2), $refs)"/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Reference style-->
                <xsl:analyze-string select="." regex="(\[(.*?)\][ ]?(?:\n[ ]*)?\[(.*?)\])" flags="!">
                    <xsl:matching-substring>
                        <xsl:variable name="id" select="lower-case(regex-group(3))"/>
                        <xsl:choose>
                            <xsl:when test="$refs/reference[@id = $id]">
                                <xsl:element name="a">
                                    <xsl:attribute name="href" select="$refs/reference[@id = $id]/@url"/>
                                    <xsl:attribute name="title" select="$refs/reference[@id = $id]/@title"/>
                                    <xsl:copy-of select="md2doc:parse-strong(regex-group(2), $refs)"/>
                                </xsl:element>                    
                            </xsl:when>
                            <xsl:when test="$refs/reference[@id = lower-case(regex-group(2))]">
                                <xsl:message><xsl:value-of select="$id"/></xsl:message>
                                <xsl:element name="a">
                                    <xsl:attribute name="href" select="$refs/reference[@id = lower-case(regex-group(2))]/@url"/>
                                    <xsl:attribute name="title" select="$refs/reference[@id = lower-case(regex-group(2))]/@title"/>
                                    <xsl:copy-of select="md2doc:parse-strong(regex-group(2), $refs)"/>
                                </xsl:element> 
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy-of select="md2doc:parse-automatic-links(.)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-automatic-links">
        <xsl:param name="input" as="xs:string*"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="&lt;((https?|ftp):[^&apos;&quot;&gt;\s]+)&gt;">
            <xsl:matching-substring>
                <xsl:element name="a">
                    <xsl:attribute name="href" select="regex-group(1)"/>
                    <xsl:copy-of select="regex-group(1)"/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
<!--                <xsl:copy-of select="md2doc:parse-strong(.)"/>-->
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:transform-to-doc">
        <xsl:param name="html-input"/>
        
        <xsl:apply-templates select="$html-input" mode="transform"/>
    </xsl:function>
    
    <!--OTHER FUNCTIONS-->
    
    <xsl:function name="md2doc:get-html">
        <xsl:param name="input" as="xs:string"/>
        <xsl:param name="refs"/>
        <xsl:sequence select="md2doc:run-block($input, $refs)"/>
    </xsl:function>
    
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
        <xsl:variable name="messages">
            <message type="error" no="1">Error with input file: incorrect encoding or missing file</message>
            <message type="error" no="2">Non matching: </message>
            
        </xsl:variable>
        <xsl:sequence select="$messages/message[@type=$type][@no=$number]/text()"/>
    </xsl:function>
    
    
</xsl:stylesheet>