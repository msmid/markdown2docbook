Markdown to DocBook Converter
=============================

Conversion tool for transforming markdown formatted text files to valid DocBook and HTML documents. Project is based on XSLT 2.0 technology.

XSL is developed under Saxon XSLT processor. See below why
 
   * Better regex support than native XPath specification (using flag `!` for java regex)
   * PHP API (Saxon/C)
   * Open-source

For demo, online converter or more info, please visit  
www.markdown2docbook.com

For official documentation, please visit:  
www.documentation.markdown2docbook.com


Features
--------

   * Markdown to Docbook 5 conversion
   * Markdown implementation in XSLT 2.0
   * Supports original Markdown syntax


Getting started
---------------

Downloading the stylesheets is pretty much all you have to do. I assume you have editors/tools for running XSLT. 
Be sure you have Saxon processor version 9.5 and higher. It doesn't matter if you have free Home Edition or commercial EE respectively PE. It works on the whole family! Let's look on intended usage scenarios.

### 1. Importing md2doc stylesheet into another stylesheet ###
      
Let's say you have your own xsl stylesheet and you want to use certain md2doc functions.
There is nothing easier. Use `<xsl:import>` element. Don't forget about namespace! Be sure to add md2doc URI                `http://www.markdown2docbook.com/ns/markdown2docbook` among other namespace declarations. Example:

    <xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
         xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"> ...
         
 Also make sure that all stylesheets (md2doc.xsl, md2doc-templates.xsl and md2doc-functions.xsl) are in the same directory.

  **Now you can use following md2doc functions:**
     
  * **convert(xs:string $input, xs:string $headline-element, xs:string $root-element)**  
    Transforms markdown string input into DocBook. Ideally used inside template that can match markdown text. Headline           element defines structure based on headlines. For example, if `$headline-element = 'chapter'` all h1 headlines are taken     as chapter and its siblings are grouped together. Otherwise root element defines if whole document should be wrapped in      root element like `<book>` or `<article>`.

    To be clear, headline element is defining component-level tag and root element is defining book (or division) level tag of             DocBook. If you want to use some component-level tag like `article` as a root one, you can use this function like this:      `md2doc:convert($input, '', 'article')`.
    
    If you don't want to use root element, leave it blank. For example:  
    `md2doc:convert($input, 'chapter', '')`  
    **WARNING** This usage may not return well-formed document!
    
    If you leave second and third argument blank, eg. `md2doc:convert($input, '','')`, headline grouping will use sect1-6 and     no root and no component elements are used. This also may not produce well-formed document.

  * **md2doc:read-file(xs:string $uri, xs:string $encoding)**  
    Attempts to read a file on path defined by $uri. If file can be located and has correct enconding as supplied by second      argument, function returns content of the file as a string. Otherwise, it shows error message. You can use this to supply     input for convert() functions.

    You can use it in conjuction with `md2doc:convert()` function as supplier for input string.

  * **md2doc:get-html(xs:string $input)**  
    This function simulates Markdown parsing into HTML. It creates same output as original parser by Mark Gruber written in      Perl. When talking about DocBook, you won't probably find usage for this function at all, but it can be used as a way how     to parse Markdown to HTML using XSLT 2.0.
    
  * **md2doc:get-processor-info()**  
    Returns information such as product name and version of installed XSLT processor.

**And also these templates**

  * **main**  
    This template is intended to be used as initial template, when you need to run md2doc on its own with source markdown        file, which transforms into DocBook and outputs xml file.
  
  * **get-html**  
    Same as `md2doc:get-html()` function, but template.

  * **convert**  
     Same as `md2doc:convert()` function, but template.
 
### 2. Using stylesheet to convert Markdown file into DocBook file ###

Because you can't run XSL over non-XML files, you have to run XSLT processor with initial template. That template is called `main` Main template, which transforms input into result document and save it on path given as parameter. Root and headline-element works exactly the same as written above. Savepath defines location and name of the file to be saved. 

  Running from command line
  
     java  -jar dir/saxon9he.jar -it:{http://www.markdown2docbook.com/ns/md2doc}main -xsl:md2doc.xsl input=input.md encoding=utf-8 root-element=book headline-element=chapter savepath=output.xml 

  XSL editors should allow you to set options and parameters in transformation scenarios.

### 3. Running stylesheet over DocBook XML document with Markdown snippets ###

The best way how to transform those snippets is to import `md2doc.xsl` into your stylesheet, add namespace, write a template to match Markdown snippet or CDATA section and use it as input in `md2doc:convert()` function. Example:
  
    <xsl:template match="programlisting[@language=markdown]">
       <xsl:copy-of select="md2doc:convert(.,'book','chapter')"/>
    </xsl:template>
    
`programlisting` is for example purposes only. Markdown doesn't has to be in such element. You can add into DocBook your own namespaced element which denotes Markdown text. But careful, on automatic escaping. If you insert some HTML into your Markdown, you have to use `CDATA` section.   

### 4. Using Md2doc for HTML output ###

If you want to use XSLT implementation for generating HTML output in the same way as original `Markdown.pl` does, use `md2doc:get-html()` function or `get-html` template.
    
Using root and headline parameters 
----------------------------------

Proper use of this stylesheet requires knowledge about your Markdown text. And also how your output should look like.  
The most essential elements are headlines. Few rules:
  
  1. Headlines are always grouping. That means, it will pull together all content until another headline of the same level        occurs. Default headline element is `<sect1-6>`. This can be changed with headline-element.  
     For example `headline-element=chapter` will create chapter element with each `<h1>` and other lower headlines will use       sections.
  2. Root-element is used for explicit root need. It wraps whole document. You can achieve this also without  
     root-element: having exactly one headline of given level and zero or more headlines of higher level in document produces      document wrapped in given headline element.
  4. You should properly use headlines.It means, you may nest headlines by levels one by one. Wrong usage is for example,         writing `h1` and then using `h3`. 
  5. Using root-element as book level structure (for example book) expects that user wants to convert stand-alone             Markdown document. It requires usage of level one headlines and headline-element declaration (eg. chapter) for proper        output.
  6. Setting headline-element blank (eg. `headline-element=''`) results with using universal `<section>` for grouping by          headlines.
     1. This is useful when you declare root-element as component level tag (eg. chapter).
     2. You will get non-valid DocBook, if you set root-element as book (or division) level tag and leave headline-element blank. It is because you can't have `<section>` as direct child of `<book>`. You have to declare headline-element as component level tag for proper output or grouping will be maintained on section level perspective.

Note: DocBook book and component elements are specified in [DocBook 5: The Definitive Guide][1].

[1]: http://www.docbook.org/tdg5/en/html/ch02.html#ch02-logdiv 


Markdown transformation
-----------------------

**Md2doc supports canonical Markdown specification by John Gruber**  
(http://daringfireball.net/projects/markdown/syntax)  
Other extensions and variants are not supported, but there is workaround: You can use HTML instead of extension markup.
  

HTML transformation
-------------------

Markdown supports subset of block HTML elements and anything from inline pool. Md2doc added some HTML5 elements and narrowed range of inline elements.

* Supported blocks:
  _address, article, aside, body, blockquote, button, div, dl, figure, fieldset, footer, form, h1-6, header, map, nav, object,   ol, p, pre, section, table, ul, video, script, noscript, iframe_

* Supported inline:
  _a, i, b, br, del, ins, img, abbr, span, small, cite, mark, dfn, kbd, samp, span, var, object, q, script, button, label,      sub, sup, textarea_

Note, that Markdown inside HTML is not parsed.  

Md2doc uses David Carlisle's HTML Parser, http://www.dcarlisle.demon.co.uk/htmlparse.xsl


* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

Martin Šmíd, 2014
