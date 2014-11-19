Markdown to DocBook - md2doc.xsl
================================

Conversion tool for transforming markdown formatted text files to valid DocBook documents. Project is based on XSLT 2.0 technology.

XSL is developed under Saxon XSLT processor. See below why
 
   * Better regex support than native XPath specification (using flag `!` for java regex)
   * PHP API (Saxon/C)
   * Great performance

For demo, converter, documentation or more info, please visit:
www.markdown2docbook.com


Features
--------

   * Markdown to Docbook 5 conversion
   * Markdown to HTML conversion
   * Outputs file or string

Getting started
---------------

Downloading the stylesheet is pretty much all you have to do. I assume you have editors/tools for running XSLT. 
Be sure you have Saxon processor version 9.5 and higher. It doesn't matter if you have free Home Edition or commercial EE respectively PE. It works on the whole family! 

### 1. Importing md2doc stylesheet into another stylesheet ###
      
  Let's say you have your own xsl stylesheet and you want to use certain md2doc functions.
  There is nothing easier. Use `<xsl:import>` element. Don't forget about namespace! Be sure to add md2doc URI                `http://www.markdown2docbook.com/ns/markdown2docbook` among other namespace declarations. Example:

    <xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
         xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"> ...

  **Now you can use following md2doc functions:**
     
  * **convert(xs:string $input, xs:string $headline-element, xs:string $root-element)**  
    Transforms markdown string input into DocBook. Ideally used inside template that can match markdown text. Headline           element defines structure based on headlines. For example, if `$headline-element = 'chapter'` all h1 headlines are taken     as chapter and its siblings are grouped together. Otherwise root element defines if whole document should be wrapped in      root element like `<book>` or `<article>`.

    To be clear, headline element is defining component-level tag and root element is defining division-level tag of             DocBook. If you want to use some component-level tag like `article` as a root one, you can use this function like this:      `md2doc:convert($input, '', 'article')`.
    
    If you don't want to use root (division-level) element, leave it blank. For example:  
    `md2doc:convert($input, 'chapter', '')`  
    **WARNING** This usage may not return well-formed document!
    
    If you leave second and third argument blank, eg. `md2doc:convert($input, '','')`, headline grouping will use sect1-6 and     no division and no component elements are used. This also may not produce well-formed document.

  * **md2doc:read-file(xs:string $uri, xs:string $encoding)**  
    Attempts to read a file on path defined by $uri. If file can be located and has correct enconding as supplied by second      argument, function returns content of the file as a string. Otherwise, it shows error message. You can use this to supply     input for convert() functions.

    You can use it in conjuction with `md2doc:convert()` function as supplier for input string.

  * **md2doc:get-html(xs:string $input)**  
    This function simulates Markdown parsing into HTML. It creates same output as original parser by Mark Gruber written in      Perl. When talking about DocBook, you won't probably find usage for this function at all, but it can be used as a way how     to parse Markdown to HTML using XSLT 2.0.
    
  * **md2doc:get-processor-info()**  
    Returns information such as product name and version of installed XSLT processor.

**And also these templates**

  * **main**  
    This is only template, which produces result document.
  
  * **get-html**
    Same as `md2doc:get-html()` function, but template.

  * **convert**
     Same as `md2doc:convert()` function, but template.
 
### 2. Using stylesheet to convert Markdown file into DocBook file ###

 Because you can't run XSL over non-XML files, you have to run XSLT processor with initial template. That template is called `main`
  
 **main**  
   @param input  
   @param encoding  
   @param root-element  
   @param headline-element  
   @param savepath   

  Main template, which transforms input into result document and save it on path given as parameter. Root and                  headline-element works exactly the same as written above. Savepath defines location and name of the file to be saved. 

  Running from command line
  
     java  -jar dir/saxon9he.jar it main input-uri=input.md encoding=utf-8 root-element=book headline-element=chapter  
     savepath=output.xml 

  XSL editors should allow you to set options and parameters in transformation scenarios.

### 3. Running stylesheet over DocBook XML document with Markdown snippets ###

  The best way how to transform those snippets is to import `md2doc.xsl` into your stylesheet, add namespace, write a template to match Markdown snippet and use it as input in `md2doc:convert()` function. Example:
  
    <xsl:template match="programlisting[@language=markdown]">
       <xsl:copy-of select="md2doc:convert(.,'book','chapter')"/>
    </xsl:template>
    
Using root and headline parameters 
----------------------------------

     md2doc:convert($input, $root-element, $headline-element)

Proper use of this stylesheet requires knowledge about your Markdown text. And also how output should look like.  
The most essential are headlines. Few rules:
  
  1. Headlines are always grouping. That means, it will pull together all content until another headline occurs.  
     Default headline element is `<sect1-6>`. This can be changed with headline-element.  
     For example `headline-element=chapter` will create chapter element with each `<h1>` and other headlines use sections.
  2. Root-element is used for explicit root usage. It is whole document wrapper. You can achieve this also without  
     root-element: having exactly one headline of given level and zero or more headlines of higher level in document.
  
  ### Scenarios

  1. I have Markdown snippet, with no headlines
     Using `root` argument will cause all markdown snippet to be wrapped.  
     Using `headline` will not cause anything because there is no headline.
  2. I have Markdown structured with multiple h1 headlines
     Using `root` argument will cause all markdown document to be wrapped.  
     Using `headline` will cause that every level one headline (and all subsequent elements) will be wrapped in headline  
     element. Level two and higher headlines will be wrapped too (in `sect1-6`).
  3. I have Markdown structured with exactly one h1 headline
     Using `root` argument will cause all markdown document to be wrapped. 
     Using `headline` will cause whole text to wrapped in headline element. For example in chapter.  
     Using both arguments will produce `<book><chapter>`, that is one component and one division structure.


HTML conversion
---------------


