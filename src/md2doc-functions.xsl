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
    
    <xsl:import href="md2doc-templates.xsl"/>
    
    <!--FUNCTIONS LIBRARY-->
    
    <xsl:function name="md2doc:convert">
        <xsl:param name="input" as="xs:string"/>
        <xsl:param name="root-element" as="xs:string"/>
        <xsl:param name="headline-element" as="xs:string"/>     
        
        <xsl:variable name="text-united" select="md2doc:unify-endlines($input)"/>
        <xsl:variable name="text-stripped-blanklines" select="md2doc:strip-blanklines($text-united)"/>
        <xsl:variable name="text-stripped-refs" select="md2doc:strip-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="refs" select="md2doc:save-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="html" select="md2doc:run-block($text-stripped-refs, $refs)"/>
        
        <xsl:sequence select="md2doc:transform-to-doc($html, $headline-element ,$root-element)"/>
        
    </xsl:function>
    
    <xsl:function name="md2doc:convert">
        <xsl:param name="uri-file" as="xs:string"/>
        <xsl:param name="encoding" as="xs:string"/>
        <xsl:param name="root-element" as="xs:string"/>
        <xsl:param name="headline-element" as="xs:string"/>     
        
        <xsl:variable name="input" select="md2doc:read-file($uri-file, $encoding)"/>
        
        <xsl:variable name="text-united" select="md2doc:unify-endlines($input)"/>
        <xsl:variable name="text-stripped-blanklines" select="md2doc:strip-blanklines($text-united)"/>
        <xsl:variable name="text-stripped-refs" select="md2doc:strip-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="refs" select="md2doc:save-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="html" select="md2doc:run-block($text-stripped-refs, $refs)"/>
        
        <xsl:sequence select="md2doc:transform-to-doc($html, $headline-element ,$root-element)"/>
        
    </xsl:function>
    
    <xsl:function name="md2doc:transform-to-doc">
        <xsl:param name="html-input"/>
        <xsl:param name="root-element"/>
        <xsl:param name="headline-element"/>
        
        <xsl:variable name="input">
            <root>
                <xsl:sequence select="$html-input"/>
            </root>
        </xsl:variable>
        
        <xsl:apply-templates select="$input" mode="md2doc:transform">
            <xsl:with-param name="root-element" select="$root-element"/>
            <xsl:with-param name="headline-element" select="$headline-element"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <!--PARSING FUNCTIONS-->
    
    <xsl:function name="md2doc:read-file">
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
    
    <xsl:function name="md2doc:unify-endlines">
        <xsl:param name="text" as="xs:string"/>
        
        <xsl:variable name="output" select="replace(replace($text,'\r\n','&#xA;'), '\r', '&#xA;')"/>
        <!--It is better when document starts and ends with 2 newlines-->
        <xsl:value-of select="concat('&#xA;&#xA;', $output, '&#xA;&#xA;')"/>
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
            regex="(?&lt;=\n\n)([ ]{{0,3}}(&lt;!(-\-(.*?)-\-\s*)+&gt;)[ \t]*(?=\n{{2,}}))" flags="m!">
            <xsl:matching-substring>
                <xsl:comment><xsl:value-of select="regex-group(4)"/></xsl:comment>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Then proceed on html block elements-->
                <xsl:analyze-string select="." 
                    regex="(^&lt;({$html-tags})\b(.*)*?&lt;/\2&gt;[ \t]*(?=\n+|\Z))" flags="m!">
                    <xsl:matching-substring>
                        <textarea><xsl:value-of select="."/></textarea>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="(^&lt;({$html-tags})\b(.*\n)*?&lt;/\2&gt;[ \t]*(?=\n+|\Z))" flags="m!">
                            <xsl:matching-substring>
                                <textarea><xsl:value-of select="."/></textarea>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <!--Dont forget on <hr />-->
                                <xsl:analyze-string select="." 
                                    regex="(?&lt;=\n\n)([ ]{{0,3}}&lt;(hr)\b([^&lt;&gt;])*?/?&gt;[ \t]*(?=\n{{2,}}))" flags="m!">
                                    <xsl:matching-substring>
                                        <hr />
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:sequence select="md2doc:parse-headers(., $refs)"/> 
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
            regex="(^(.+)[ \t]*\n(=+)[ \t]*\n+)|(^(.+)[ \t]*\n(-+)[ \t]*\n+?)" flags="m">
<!--            (^(.+)[ \t]*\n(=+)[ \t]*$)|(^(.+)[ \t]*\n(-+)[ \t]*$)-->
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(.,'=')">
                        <h1><xsl:sequence select="md2doc:run-inline(normalize-space(regex-group(2)), $refs)"/></h1>
                    </xsl:when>
                    <xsl:otherwise>
                        <h2><xsl:sequence select="md2doc:run-inline(normalize-space(regex-group(5)), $refs)"/></h2>
                    </xsl:otherwise>
                </xsl:choose>         
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--atx style-->
                <xsl:analyze-string select="." regex="^(#{{1,6}})[ \t]*(.+)[ \t]*#*\n*?" flags="m">
<!--                    ^(#{{1,6}})[ \t]*(.+?)[ \t]*#*$ -->
                    <xsl:matching-substring>
                        <xsl:element name="h{string-length(regex-group(1))}">
                            <xsl:sequence select="md2doc:run-inline(normalize-space(regex-group(2)), $refs)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-rulers(., $refs)"/>
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
                                <xsl:sequence select="md2doc:parse-lists(., $refs)"/>
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
            regex="((^([ ]{{0,3}})([*+-]|\d+[.])[ \t]+)(.+\n)*\n*( .+\n*)*)+" flags="m!">
            <xsl:matching-substring>
                <xsl:variable name="indent">
                    <xsl:analyze-string select="." regex="^( {{0,3}}).+">
                        <xsl:matching-substring>
                            <xsl:sequence select="string-length(regex-group(1))"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                <xsl:element name="{if (matches(.,'^[ ]*[*+-]','m')) then 'ul' else 'ol'}">
                    <xsl:sequence select="md2doc:parse-list-items(., $indent, $refs)"/>
                </xsl:element>
                <!--debug-->
                <!--<obsahListu>&LF;<xsl:copy-of select="."/></obsahListu>
                <indent><xsl:copy-of select="$indent"/></indent>  -->                        
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--<xsl:copy-of select="md2doc:parse-blockquotes(concat(., '&#xA;&#xA;'))"/>-->
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
                        <xsl:analyze-string select="$trim" regex="^ *([*+-]|\d+\.)(.+)$" flags="m!">
                            <xsl:matching-substring>
                                <xsl:value-of select="
                                    if ($indent != 0) 
                                    then replace(., concat('^ {', $indent, '}'),'','m') 
                                    else replace(., concat('^ {', 1, '}'),'','m')"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:variable name="del" select="concat('^ {', 4 - $indent, '}')"/>
                                <xsl:value-of select="replace(.,$del,'','m')"/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:sequence select="md2doc:run-block($chop, $refs)"/>
                    <!--debug-->
                    <!--<input><xsl:copy-of select="$input"/></input>
                    <strip><xsl:copy-of select="$stripList"/></strip>
                    <trim><xsl:copy-of select="$trim"/></trim>
                    <chop><xsl:copy-of select="$chop"/></chop>-->
                </li>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--here is dead end-->
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
                        <xsl:value-of select="replace(.,'^\n+ {4}','')" disable-output-escaping="yes"/>
                    </code>
                </pre>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="md2doc:parse-blockquotes(., $refs)"/>
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
                    <xsl:variable name="trim" select="replace(.,'^[ \t]*&gt; ?','','m')"/>
                    <xsl:sequence select="md2doc:run-block(replace($trim,'^[ \t]+$','','m'), $refs)"/>
                </blockquote>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="md2doc:parse-paragraphs(., $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-paragraphs">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
<!--        <inputText><xsl:value-of select="$text"/></inputText>-->
        <!--<xsl:analyze-string select="$text" regex="^.+\n{{2,}}" flags="m">
            <xsl:matching-substring>
                <p><xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),'([ ]|\n)+$',''), $refs)"/></p>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),'([ ]|\n)+$',''), $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>-->
        
<!--        <xsl:variable name="split" select="tokenize(replace(replace($text,'^\n',''),'\n+$',''),'\n{2,}')"/>-->
        <xsl:variable name="split" select="tokenize($text,'\n{2,}')"/>
        <xsl:for-each select="$split">
            <xsl:choose>
                <xsl:when test="matches(.,'^$')">
                    
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="matches(.,'\n$')">
                            <xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),'([ ]|\n)+$',''), $refs)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <p><xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),'([ ]|\n)+$',''), $refs)"/></p>
<!--                            <paracontent><xsl:value-of select="."/></paracontent>-->
                        </xsl:otherwise>
                    </xsl:choose>
                    <!--<p><xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),'([ ]|\n)+$',''), $refs)"/></p>
                    <paracontent><xsl:value-of select="."/></paracontent>-->
                </xsl:otherwise>
            </xsl:choose>
            
            <!--<p><xsl:copy-of select="md2doc:run-inline(replace(replace(replace(.,'\n',' '),'^ +',''),' +$',''), $refs)"/></p>-->
            <!--<p><xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),' +$',''), $refs)"/></p>
            <paracontent><xsl:value-of select="."/></paracontent>-->
            <!--<xsl:choose>
                <xsl:when test="matches(.,'\n$')">
                    <p><xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),' +$',''), $refs)"/></p>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="md2doc:run-inline(replace(replace(.,'^ +',''),' +$',''), $refs)"/>
                </xsl:otherwise>
            </xsl:choose>-->
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="md2doc:run-inline">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:sequence select="md2doc:parse-codespans($text, $refs)"/>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-codespans">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" 
            regex="(\*|_)+(?=\S)(.*?[*_]*)(?&lt;!\\)(`+)(.+?)(?&lt;!`)\3(?!`).*?(?&lt;=\S)(\*|_)+" flags="!">
            <xsl:matching-substring>
                <xsl:sequence select="md2doc:parse-spans(., $refs)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:analyze-string select="." regex="(?&lt;!\\)(`+)(.+?)(?&lt;!`)\1(?!`)" flags="!">
                    <xsl:matching-substring>
                        <code><xsl:value-of select="normalize-space(regex-group(2))"/></code>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-inline-html(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-inline-html">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(&lt;(\w+)\b(.*\n)*?.*&lt;/\2&gt;)" flags="!">
            <xsl:matching-substring>
                <textarea><xsl:sequence select="md2doc:parse-codespans(.,$refs)"/></textarea>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="md2doc:parse-spans(.,$refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>      
    </xsl:function>
    
    <xsl:function name="md2doc:parse-spans">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="(\*|_)+(?=\S)(.+?[*_]*)(?&lt;=\S)(\*|_)" flags="!">
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(.,'^(\*\*|__)') and matches(.,'(\*\*|__)$')">
                        <strong><xsl:sequence select="md2doc:parse-codespans(replace(replace(.,'^(\*\*|__)',''),'(\*\*|__)$',''),$refs)"/></strong>
                    </xsl:when>
                    <xsl:when test="matches(.,'^(\*|_)') and matches(.,'(\*|_)$')">
                        <em><xsl:sequence select="md2doc:parse-codespans(replace(replace(.,'^(\*|_)',''),'(\*|_)$',''),$refs)"/></em>
                    </xsl:when>
                    <xsl:otherwise>
                        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="md2doc:parse-images(., $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-images">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--Inline style images-->
        <xsl:analyze-string select="$text" 
            regex="(!\[(.*?)\]\([ \t]*&lt;?(\S+?)&gt;?[ \t]*(([&quot;])(.*?)\5[ \t]*)?\))" flags="">
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
                                <xsl:sequence select="md2doc:run-inline(., $refs)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-anchors(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-anchors">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--Inline style first-->
        <xsl:analyze-string select="$text" 
            regex="(\[(.*?)\]\([ \t]*&lt;?(.*?)&gt;?[ \t]*(([&quot;])(.*?)\5)?\))" flags="!">
            <xsl:matching-substring>
                <xsl:element name="a">
                    <xsl:attribute name="href" select="regex-group(3)"/>
                    <xsl:attribute name="title" select="regex-group(6)"/>
                    <xsl:copy-of select="md2doc:parse-codespans(regex-group(2), $refs)"/>
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
                                    <xsl:copy-of select="md2doc:parse-codespans(regex-group(2), $refs)"/>
                                </xsl:element>                    
                            </xsl:when>
                            <xsl:when test="$refs/reference[@id = lower-case(regex-group(2))]">
                                <xsl:element name="a">
                                    <xsl:attribute name="href" select="$refs/reference[@id = lower-case(regex-group(2))]/@url"/>
                                    <xsl:attribute name="title" select="$refs/reference[@id = lower-case(regex-group(2))]/@title"/>
                                    <xsl:copy-of select="md2doc:parse-codespans(regex-group(2), $refs)"/>
                                </xsl:element> 
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="md2doc:run-inline(., $refs)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-automatic-links(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-automatic-links">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="&lt;((https?|ftp):[^&apos;&quot;&gt;\s]+)&gt;">
            <xsl:matching-substring>
                <xsl:element name="a">
                    <xsl:attribute name="href" select="regex-group(1)"/>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:element>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="md2doc:parse-special-chars(.,$refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="md2doc:parse-special-chars">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="chars" select="'\\(?=[\\`*_{}\[\]()#+\-.!&gt;])'"/>
        <xsl:sequence select="replace($text,$chars,'','!')"/>
    </xsl:function>
    
    <xsl:function name="md2doc:get-html">
        <xsl:param name="input" as="xs:string"/>
        <xsl:variable name="text-united" select="md2doc:unify-endlines($input)"/>
        <xsl:variable name="text-stripped-blanklines" select="md2doc:strip-blanklines($text-united)"/>
        <xsl:variable name="text-stripped-refs" select="md2doc:strip-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="refs" select="md2doc:save-references($text-stripped-blanklines)"/>
        
        <xsl:sequence select="md2doc:run-block($text-stripped-refs, $refs)"/>
    </xsl:function>
    
    <!--OTHER FUNCTIONS-->
    
    <xsl:function name="md2doc:get-processor-info">
        <xsl:variable name="output">
            <xsl:value-of select="'&#xA;XSLT ',system-property('xsl:version')" />
            <xsl:value-of select="'&#xA;Vendor: ', system-property('xsl:vendor')" />
            <xsl:value-of select="' ', system-property('xsl:vendor-url')" />
            <xsl:value-of select="'&#xA;Product name: ', system-property('xsl:product-name')" />
            <xsl:value-of select="'&#xA;Product version: ', system-property('xsl:product-version')" />
        </xsl:variable>
        <xsl:sequence select="$output"/>
    </xsl:function>
    
    <xsl:function name="md2doc:print-disclaimer">
        <xsl:comment>
Generated using md2doc.xsl by Martin Smid ©2014
on <xsl:value-of select="current-dateTime()"/>
------------------------<xsl:value-of select="md2doc:get-processor-info()"/>
        </xsl:comment>&LF;
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