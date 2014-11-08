<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY LF "<xsl:text>&#xA;</xsl:text>">
]>
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:d="http://docbook.org/ns/docbook"
    xmlns:xl="http://www.w3.org/1999/xlink"
    xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"   
    exclude-result-prefixes="xs xl d md2doc"
    xpath-default-namespace="">
    
    <!--importing sheet with functions-->
    <xsl:import href="md2doc-functions.xsl"/>
    
    <xsl:output omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
    <xsl:output name="docbook" encoding="UTF-8" method="xml" indent="yes"/>
    <xsl:output name="html" encoding="UTF-8" doctype-system="http://www.w3.org/TR/html4/strict.dtd"
        doctype-public="-//W3C//DTD HTML 4.01//EN"/>

    <!--Parameters for input text file NOTE: přidej required-->
    
    <!--Specifies if all document should be wrapped in element (like Book or perhaps Chapter)-->
    <xsl:param name="root-element" as="xs:string" select="'book'"/>
    <!--Specifies which docbook element should be match with h1 headlines-->
    <xsl:param name="headline-element" as="xs:string" select="'chapter'"/>
    
    <xsl:param name="input-string" as="xs:string" select="'# header'"/>
    <xsl:param name="input" as="xs:string" select="'../test/in/test-frag.md'"/>
    <xsl:param name="url-file" as="xs:string"/>
    <xsl:param name="encoding-file " as="xs:string" select="string('UTF-8')"/>
    <xsl:param name="url-savepath" as="xs:string" select="'../test/out/output.xml'"/>
    <!--<xsl:param name="docBooktemplate" as="xs:string"/>
    <xsl:param name="outputMethod"/>-->

    <xsl:template name="main-from-string">
        <xsl:variable name="input" select="md2doc:read-string($input-string)"/>
        <xsl:sequence select="md2doc:main($input)"/>
    </xsl:template>
    
    <!--Main template to be called at the start of transformation-->
    <xsl:template name="main-from-file">
        
<!--        <xsl:copy-of select="md2doc:parse-codespans('text **tucne `kod` tucne** konec ***`ada`*** vety.','')"/>-->
        
        <xsl:result-document href="../test/out/output3.xml" format="docbook">&LF;
            <xsl:variable name="input" select="md2doc:read-file('../test/in/test-frag.md','utf-8')"/>
            
            <!--takovyhle template aby slo to html-->
            <xsl:variable name="html">
                <xsl:sequence select="md2doc:get-html($input)"/>
            </xsl:variable>
            
            <xsl:sequence select="md2doc:transform-to-doc($html,$headline-element)"/>


        </xsl:result-document>
        
        <xsl:result-document href="../test/out/output2.xml" format="docbook">&LF;
           
            <!--<xsl:variable name="input" select="md2doc:read-file('../test/in/test2.md','utf-8')"/>
            <xsl:sequence select="md2doc:main($input, $root-element)"/>-->
            
        </xsl:result-document>
        
        <xsl:result-document href="{$url-savepath}" format="docbook">&LF;
            <xsl:variable name="input" select="md2doc:read-file('../test/in/test-frag.md','utf-8')"/>

<!--            <xsl:copy-of select="md2doc:run-block($text-stripped-blanklines)"/>-->
            
            <xsl:sequence select="md2doc:get-html($input)"/>
<!--            <xsl:copy-of select="md2doc:main($input)"/>-->
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
            
            <!--takovyhle template aby slo to html-->
            <xsl:variable name="html">
                <xsl:sequence select="md2doc:get-html($input)"/>
            </xsl:variable>
            
            <xsl:sequence select="md2doc:transform-to-doc($html)"/>
            
            
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="main-xml">
        
    </xsl:template>
        
    <!--<xsl:template match="/" mode="#all">
        <xsl:apply-templates select="*"/> 
        <xsl:message>document rule: <xsl:copy-of select="."/></xsl:message>
    </xsl:template>-->
    
    <xsl:template match="root">
        <xsl:choose>
            <xsl:when test="$root-element != ''">
                <xsl:element name="{$root-element}">
                    <xsl:call-template name="headline-grouping"/>
                </xsl:element>    
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="headline-grouping"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="headline-grouping">
        <xsl:for-each-group select="*" 
            group-starting-with="h1|
            h2[not(preceding-sibling::h1)]|
            h3[not(preceding-sibling::h2)]|
            h4[not(preceding-sibling::h3)]|
            h5[not(preceding-sibling::h4)]|
            h6[not(preceding-sibling::h5)]
            ">                    
            <xsl:apply-templates select="." mode="group"/>
        </xsl:for-each-group>
    </xsl:template>
    
    <xsl:template match="h1|h2|h3|h4|h5|h6" mode="group">
        <xsl:variable name="this" select="name()"/>
        <xsl:variable name="next" select="translate($this, '123456', '234567')"/>
        <xsl:element name="{
            if ($this eq 'h1' and $headline-element != '') 
            then $headline-element 
            else concat('sect',translate(replace($this,'h',''),'23456','12345'))
            }">
            <title><xsl:value-of select="."/></title>
            <xsl:for-each-group select="current-group() except ." group-starting-with="*[name() = $next]">
                <xsl:apply-templates select="." mode="group"/>
<!--                <xsl:message>hX rule: <xsl:copy-of select="."/></xsl:message>-->
            </xsl:for-each-group>
        </xsl:element>
    </xsl:template> 
    
    <xsl:template match="p" mode="group">
        <xsl:apply-templates select="current-group()"/>
<!--        <xsl:message select="'Rule * group mode: ', current-group()"/>-->
    </xsl:template>
    
    <xsl:template match="p">
<!--        <para><xsl:copy-of select="node()|@*"/></para>-->
        <para><xsl:apply-templates/></para>
<!--        <xsl:message select="'Rule p no mode: ', ."/>-->
    </xsl:template>
    
    <xsl:template match="blockquote" mode="group">
        <xsl:apply-templates select="current-group()"/>
    </xsl:template>
    
    <xsl:template match="blockquote">
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
       
    <xsl:template match="blockquote/h1">
        <title><xsl:apply-templates/></title>
    </xsl:template>
    
    <!--<xsl:template match="blockquote/pre">
        <example>
            <xsl:apply-templates/>
        </example>
    </xsl:template>-->
    
    <xsl:template match="ul" mode="group">
        <xsl:apply-templates select="current-group()"/>
    </xsl:template>
    
    <xsl:template match="ul">
        <itemizedlist>
            <xsl:apply-templates/>
        </itemizedlist>
    </xsl:template>
    
    <xsl:template match="ol" mode="group">
        <xsl:apply-templates select="current-group()"/>
    </xsl:template>
    
    <xsl:template match="ol">
        <orderedlist>
            <xsl:apply-templates select="*"/>
        </orderedlist>
    </xsl:template>
    
    <xsl:template match="li">
        <listitem>
            <xsl:apply-templates select="*"/>
        </listitem>
    </xsl:template>
    
    <xsl:template match="li/h1">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="pre" mode="group">
        <xsl:apply-templates select="current-group()"/>
    </xsl:template>
    
    <xsl:template match="pre">
        <example>
            <xsl:apply-templates/>    
        </example>
    </xsl:template>
    
    <xsl:template match="code[ancestor::pre]">
        <programlisting>         
            <xsl:value-of select="." disable-output-escaping="no"/>
        </programlisting>
    </xsl:template>
    
    <xsl:template match="xmp" mode="group">
        <xsl:apply-templates select="current-group()"/>      
    </xsl:template>
    
    <xsl:template match="hr" mode="group">
        <xsl:apply-templates select="current-group()"/>
    </xsl:template>
    
    <xsl:template match="hr"/>
    
    <!--to html by chtelo osetrit jeste driv, a samotny html elementy pres identity template-->
    <xsl:template match="xmp">
        <xsl:value-of select="text()" disable-output-escaping="yes"/>      
    </xsl:template>
    
    <xsl:template match="code">
        <computeroutput>
            <xsl:value-of select="." disable-output-escaping="yes"/>
        </computeroutput>
    </xsl:template>
    
    <xsl:template match="em|strong">
        <emphasis>
            <xsl:apply-templates select="node()|@*"/>
        </emphasis>
    </xsl:template>
    
    <!--strong nema tak nejak opak v docbooku-->
    <!--<xsl:template match="strong">
        <emphasis>
            <xsl:apply-templates select="node()|@*"/>
        </emphasis>
    </xsl:template>-->
    
    <xsl:template match="img">
        <inlinemediaobject>
            <imageobject>
                <imagedata fileref="{@src}"/>
            </imageobject>
            <alt><xsl:value-of select="@alt"/></alt>
            <!--existuje i alt tag a kam dam title informaci?-->
        </inlinemediaobject>
    </xsl:template>
    
    <xsl:template match="a">
        <link>
            <xsl:attribute name="xl:href">
                <xsl:value-of select="@href"/>
            </xsl:attribute>
            <xsl:if test="@href != ''">
                <alt><xsl:value-of select="@title"/></alt>
            </xsl:if>         
            <xsl:apply-templates select="*"/>
        </link>
    </xsl:template>
    
    <xsl:template match="node()|@*" name="identity" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template name="md2doc:convert">
        <xsl:param name="input"/>
        <xsl:param name="root-tag"/>
        <xsl:copy-of select="$root-tag"/>
    </xsl:template>
    
</xsl:transform>
