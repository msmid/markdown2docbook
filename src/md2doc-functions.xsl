<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"
    xmlns:d="data:,dpc"
    exclude-result-prefixes="xs d md2doc"
    version="2.0">
    
    <!--
        FUNCTION LIBRARY stylesheet
        
        Markdown Parser in XSLT2 Copyright 2014 Martin Šmíd
        This code is under MIT licence, see more at https://github.com/MSmid/markdown2docbook
    -->
    
    <xsl:import href="md2doc-templates.xsl"/>
    <xsl:import href="htmlparse.xsl"/>
    
    <!--
    ! Main converting function. Transform input string into Docbook.
    !
    ! @param $input the string to be parsed
    ! @param $root-element specifies if root element is needed
    ! @param $headline-element specifies if h1 elements should be wrapped in passed element
    ! @return generated DocBook document
    -->
    <xsl:function name="md2doc:convert">
        <xsl:param name="input" as="xs:string"/>
        <xsl:param name="root-element" as="xs:string"/>
        <xsl:param name="headline-element" as="xs:string"/>     
        
        <xsl:variable name="text-united" select="md2doc:unify-endlines($input)"/>
        <xsl:variable name="text-stripped-blanklines" select="md2doc:strip-blanklines($text-united)"/>
        <xsl:variable name="text-stripped-refs" select="md2doc:strip-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="refs" select="md2doc:save-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="html" select="md2doc:run-block($text-stripped-refs, $refs)"/>
        
        <xsl:sequence select="md2doc:transform-to-doc($html, $root-element, $headline-element)"/>
        
    </xsl:function>
    
    <!--
    ! Function responsible for transforming HTML into DocBook.
    !
    ! @param $html-input html document to be transformed
    ! @param $root-element specifies if root element is needed
    ! @param $headline-element specifies if h1 elements should be wrapped in passed element
    ! @return generated DocBook document
    -->
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
    
    <!--
    ! Simple function that handles reading from the file. Return error message if something gone wrong.
    !
    ! @param $uri location of the input file
    ! @param $encoding of the input file
    ! @return string content of the file
    -->
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
    
    <!--
    ! Unify endlines into single newline feed character for easier parsing.
    ! Also adding two newlines at the start and the end of text.
    !
    ! @param $text to be unified
    ! @return text prepared for parsing
    -->
    <xsl:function name="md2doc:unify-endlines">
        <xsl:param name="text" as="xs:string"/>
        
        <xsl:variable name="output" select="replace(replace($text,'\r\n','&#xA;'), '\r', '&#xA;')"/>
        <!--It is better when document starts and ends with 2 newlines-->
        <xsl:value-of select="concat('&#xA;&#xA;', $output, '&#xA;&#xA;')"/>
    </xsl:function>
    
    <!--
    ! Lines which contain only whitespace are stripped, leaving only newline char.
    ! We want to know, where are "blanklines" but we don't need any spaces, tabs etc.
    !
    ! @param $text to be stripped
    ! @return text prepared for parsing
    -->
    <xsl:function name="md2doc:strip-blanklines">
        <xsl:param name="text" as="xs:string"/>
        
        <xsl:analyze-string select="$text" regex="^[ \t]+?$" flags="m">
            <xsl:matching-substring/>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--
    ! Before any other action, parser needs to find and save references from text.
    ! They are used for link and images (as href, respectively src attributes). 
    !
    ! @param $input to find and save references
    ! @return references representation
    -->
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
    
    <!--
    ! References aren't displayed in final document, so we need to strip them, before
    ! we start parsing.
    !
    ! @param $input where references will be stripped
    ! @return text prepared for parsing
    -->
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
    
    <!--
    ! Initializing descent recursive regexp parsing logic. Starting with block elements,
    ! then proceeding on inline elements.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:run-block">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="result" select="md2doc:parse-codeblocks($text, $refs)"/>
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <!--
    ! Parse markdown codeblocks and return html representation. This function is invoked first.
    ! Left string is supplied into next function.
    !
    ! @param $input to be parsed 
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
                <xsl:sequence select="md2doc:parse-headers(., $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--
    ! Parse ATX and setext style headers. Unparsed string is supplied into next function.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:parse-headers">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--setext style-->
        <xsl:analyze-string select="$text" 
            regex="(^(.+)[ \t]*\n(=+)[ \t]*\n+)|(^(.+)[ \t]*\n(-+)[ \t]*\n+?)" flags="m">
            <xsl:matching-substring>
                <xsl:choose>
                    <xsl:when test="matches(regex-group(3),'=')">
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
                        <xsl:variable name="level" select="string-length(regex-group(1))"/>
                        <xsl:element name="h{$level}">
                            <xsl:sequence select="
                                md2doc:run-inline(
                                    normalize-space(
                                        replace(regex-group(2),concat('#{',$level,'}$'),'')
                                    )
                                , $refs)
                            "/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-rulers(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>         
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>   
    
    <!--
    ! Parse three types of rulers separately. Unparsed string is supplied into next function.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
    
    <!--
    ! Finds list block and decide if it is <ul> or <ol>. Then calls function for processing list items.
    ! Unparsed string is supplied into next function.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
                    <xsl:sequence select="md2doc:parse-list-items(md2doc:detab(.), $indent, $refs)"/>
                </xsl:element>
                <!--debug-->
                <!--<obsahListu>&LF;<xsl:copy-of select="."/></obsahListu>
                <indent><xsl:copy-of select="$indent"/></indent>  -->                        
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--<xsl:copy-of select="md2doc:parse-blockquotes(concat(., '&#xA;&#xA;'))"/>-->
                <xsl:sequence select="md2doc:parse-blockquotes(., $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--
    ! Dead-end function, which is used for parsing list items. It receives whole list block, which
    ! cuts into list items and its sub-list items (list items are found with given indent). List items with
    ! same indent are considered as siblings, but list items with indent smaller or bigger are considered as their
    ! children and they will be turned into new list block. Other markdown will be parsed accordingly to their markup.
    ! List items and other elements are stripped, trimmed, chopped and sent recursively to run-block function.
    !
    ! @param $input to be parsed
    ! @param $indent of list item. 
    ! @param $refs represents saved references
    ! @return parsed markdown in <li> elements
    -->
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
    
    <!--
    ! Parse blockquotes. They are trimmed and "inner" text is sent into run-block() for recursive parsing.
    ! Unparsed string is supplied into next function.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
                <xsl:sequence select="md2doc:parse-block-html(., $refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--
    ! Function, that handles and parses HTML elements which are allowed in Markdown document. First we need to 
    ! identify HTML "stuff": comments, regular elements and self-closing tags. After that, 
    ! we call external function d:htmlparse from David Carlisle's stylesheet to build HTML nodes from this "literal" HTML.
    ! Note: function use whitelist of accepted HTML for two reasons:
    ! 1) Regexp is way more faster with finding <div> than <\w+>
    ! 2) Gruber's parser also accepts whitelist HTML
    ! I added some more tags, but I still sticks to the whitelist, because I dont want to slow down regexp.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed literal HTML into HTML document
    -->
    <xsl:function name="md2doc:parse-block-html">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--List of accepted block html elements-->
        <xsl:variable name="block-html" 
            select="concat('address|article|aside|body|blockquote|button|div|dl|',
            'figure|fieldset|footer|form|h[1-6]|header|map|nav|object|ol|p|pre|section|',
            'table|ul|video|script|noscript|iframe')"/> 
      
        <xsl:analyze-string select="$text" 
            regex="(?&lt;=\n\n)([ ]{{0,3}}(&lt;!(-\-(.*?)-\-\s*)+&gt;)[ \t]*(?=\n{{2,}}))" flags="m!">
            <xsl:matching-substring>
                <xsl:comment><xsl:value-of select="regex-group(4)"/></xsl:comment>
                <!--<xsl:message select="."/>-->
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Then proceed on html block elements-->
                <xsl:analyze-string select="." 
                    regex="(^&lt;({$block-html})\b(.*)*?&lt;/\2&gt;[ \t]*(?=\n+|\Z))" flags="m!">
                    <xsl:matching-substring>
                        <!--<textarea><xsl:value-of select="."/></textarea>-->
                        <xsl:sequence select="d:htmlparse(.,'',true())"/>
                        <!--<xsl:message select="."/>-->
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="(^&lt;({$block-html})\b(.*\n)*?&lt;/\2&gt;[ \t]*(?=\n+|\Z))" flags="m!">
                            <xsl:matching-substring>
                                <!--<textarea><xsl:value-of select="."/></textarea>-->
                                <xsl:sequence select="d:htmlparse(.,'',true())"/>
                                <!--<xsl:message select="."/>-->
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <!--Dont forget on self-closing tags-->
                                <xsl:analyze-string select="." 
                                    regex="(?&lt;=\n\n)([ ]{{0,3}}&lt;(embed|hr|br|img)\b([^&lt;&gt;])*?/?&gt;[ \t]*(?=\n{{2,}}))" flags="m!">
                                    <xsl:matching-substring>
                                        <xsl:sequence select="d:htmlparse(.,'',true())"/>
                                        <!--<xsl:message select="."/>-->
                                    </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                        <xsl:sequence select="md2doc:parse-paragraphs(., $refs)"/> 
                                        <!--<xsl:message select="."/>-->
                                    </xsl:non-matching-substring>                                  
                                </xsl:analyze-string>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>   
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--
    ! Last block-level parsing function. It splits input by newlines, decides which ones will be wrapped
    ! in <p> (list items can be without <p> if they aren't separated by blankline) and sends into run-inline
    ! function.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
                    <!--Omitting blanklines-->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="matches(.,'\n$')">
                            <xsl:sequence select="md2doc:run-inline(replace(.,'^ +',''), $refs)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <p><xsl:sequence select="md2doc:run-inline(replace(.,'^ +',''), $refs)"/></p>
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
    
    <!--
    ! This function invokes parsing of inline markdown in similar fashion as run-block().
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:run-inline">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:sequence select="md2doc:parse-codespans($text, $refs)"/>
    </xsl:function>
    
    <!--
    ! Like parse-codeblocks(), we have to parse inline codespans first.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
    
    <!--
    ! Inline HTML markup needs to be parsed. Gruber's parser leaves this alone, so it becomes source of bugs
    ! (for example: *<q>quote*</q> produces <em><q>quote</em></q>).
    ! To avoid this behaviour I need to parse them. There is one difference with Gruber's parser:
    ! You will not get Markdown inside inline HTML parsed!
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:parse-inline-html">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--List of accepted html elements-->
        <xsl:variable name="inline-html" 
            select="concat('a|i|b|del|ins|abbr|span|small|cite|mark|dfn|',
            'kbd|samp|span|var|object|q|script|button|label|sub|sup|textarea')"/>
        <xsl:analyze-string select="$text" regex="(&lt;({$inline-html})\b((.*\n)*?.*)&lt;/\2&gt;)" flags="!">
            <xsl:matching-substring>
                <xsl:sequence select="d:htmlparse(.,'',true())"/>
                <!--<xsl:element name="{regex-group(2)}">
                        <xsl:sequence select="md2doc:run-inline(replace(regex-group(3),'>',''),$refs)"/>
                    </xsl:element>-->
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:analyze-string select="." regex="&lt;(a|embed|br|img)\b([^&lt;&gt;])*?/?&gt;" flags="!">
                    <xsl:matching-substring>
                        <xsl:sequence select="d:htmlparse(.,'',true())"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-hardbreaks(.,$refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string> 
        
        
    </xsl:function>
    
    <!--
    ! Parsing of hardbreaks, which are used for forcing linebreak.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:parse-hardbreaks">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:analyze-string select="$text" regex="[ ]{{2,}}\n" flags="">
            <xsl:matching-substring>
                <br />
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:sequence select="md2doc:parse-spans(.,$refs)"/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--
    ! Parsing of strong and em markdown markup.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
    
    <!--
    ! Parsing of images, both inline and reference styles. For reference style, function looks up in $refs
    ! and create <img> by id.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:parse-images">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--Reference style-->
        <xsl:analyze-string select="$text" regex="(!\[(.*?)\][ ]?(?:\n[ ]*)?\[(.*?)\])" flags="!">
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
                <!--Inline style images-->
                <xsl:analyze-string select="." 
                    regex="(!\[(.*?)\]\([ \t]*&lt;?(\S+?)&gt;?[ \t]*(([&quot;])(.*?)\5[ \t]*)?\))" flags="">
                    <xsl:matching-substring>
                        <xsl:element name="img">
                            <xsl:attribute name="src" select="regex-group(3)"/>
                            <xsl:attribute name="alt" select="regex-group(2)"/>
                            <xsl:attribute name="title" select="regex-group(6)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-anchors(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
        
    </xsl:function>
    
    <!--
    ! Parsing of anchors, both inline and reference styles. For reference style, function looks up in $refs
    ! and create <a> by id.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:parse-anchors">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <!--Reference style first-->
        <xsl:analyze-string select="$text" regex="(\[(.*?)\][ ]?(?:\n[ ]*)?\[(.*?)\])" flags="!">
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
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <!--Inline style-->
                <xsl:analyze-string select="." 
                    regex="(\[(.*?)\]\([ \t]*&lt;?(.*?)&gt;?[ \t]*(([&quot;])(.*?)\5)?\))" flags="!">
                    <xsl:matching-substring>
                        <xsl:element name="a">
                            <xsl:attribute name="href" select="regex-group(3)"/>
                            <xsl:attribute name="title" select="regex-group(6)"/>
                            <xsl:copy-of select="md2doc:parse-codespans(regex-group(2), $refs)"/>
                        </xsl:element>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:sequence select="md2doc:parse-automatic-links(., $refs)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
        
    </xsl:function>
    
    <!--
    ! Parsing of links (eg. <http://www.markdown2docbook.com> ). They have to be in enclosed in angle brackets.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
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
    
    <!--
    ! Function, that unespaces special characters, whose are meaningful both in HTML and Markdown.
    !
    ! @param $input to be parsed
    ! @param $refs represents saved references
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:parse-special-chars">
        <xsl:param name="input" as="xs:string*"/>
        <xsl:param name="refs"/>
        
        <xsl:variable name="text" select="string-join($input,'')"/>
        <xsl:variable name="chars" select="'\\(?=[\\`*_{}\[\]()#+\-.!&gt;])'"/>
        <xsl:sequence select="replace($text,$chars,'','!')"/>
    </xsl:function>
    
    <!--
    ! Finds leading chars and tab, then counts how many spaces should replace the tab.
    !
    ! @param $text to be detabed
    ! @return text with replaced tabs
    -->
    <xsl:function name="md2doc:detab">
        <xsl:param name="text" as="xs:string"/>
        
        <xsl:analyze-string select="$text" regex="^(.*?)\t" flags="m">
            <xsl:matching-substring>
                <xsl:variable name="trim" select="string-length(regex-group(1))"/>
                <xsl:variable name="detab" 
                    select="if ($trim != 0) 
                            then replace('    ', concat('^ {',$trim,'}'), '')
                            else string('    ')"
                />
                <xsl:sequence select="replace(.,'\t',$detab)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    <!--
    ! This serves (as name implied) to get HTML document out of Markdown. If user wants to get only HTML,
    ! he uses this function instead of convert() which returns DocBook document.
    !
    ! @param $input to be parsed
    ! @return parsed markdown into HTML document
    -->
    <xsl:function name="md2doc:get-html">
        <xsl:param name="input" as="xs:string"/>
        <xsl:variable name="text-united" select="md2doc:unify-endlines($input)"/>
        <xsl:variable name="text-stripped-blanklines" select="md2doc:strip-blanklines($text-united)"/>
        <xsl:variable name="text-stripped-refs" select="md2doc:strip-references($text-stripped-blanklines)"/>
        
        <xsl:variable name="refs" select="md2doc:save-references($text-stripped-blanklines)"/>
        
        <xsl:sequence select="md2doc:run-block($text-stripped-refs, $refs)"/>
    </xsl:function>
    
    <!--
    ! Simple function which displays information about user's XSLT processor.
    !
    ! @return info about user's XSLT processor
    -->
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
    
    <!--
    ! Function, which outputs messages to help determine what is going on. 
    !
    ! @param $number of the message
    ! @param $type of the message
    ! @return message
    -->
    <xsl:function name="md2doc:alert">
        <xsl:param name="number" as="xs:integer"/>
        <xsl:param name="type" as="xs:string"/>
        <xsl:variable name="messages">
            <message type="error" no="1">MD2Doc: Error with input file: incorrect encoding or missing file</message>
            <message type="error" no="2">MD2Doc: Non matching: </message>
        </xsl:variable>
        <xsl:sequence select="$messages/message[@type=$type][@no=$number]/text()"/>
    </xsl:function>
      
</xsl:stylesheet>