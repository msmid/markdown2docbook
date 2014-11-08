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

   * Awesome everything!
   * Cake is a lie!

Getting started
---------------

Downloading the stylesheet is pretty much all you have to do. I assume you have editors/tools for running XSLT. 
Be sure you have Saxon processor version 9.5 and higher. It doesn't matter if you have free Home Edition or commercial EE respectively PE. It works on the whole family! 

### 1. Importing md2doc stylesheet into another stylesheet ###
      
  Let's say you have your own xsl stylesheet and you want to use certain md2doc functions.
  There is nothing easier. Use `<xsl:import>` element. Don't forget about namespace! Be sure to add md2doc URI                `http://www.markdown2docbook.com/ns/markdown2docbook` among other namespace declarations. Example:

    <xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
         xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"> ...

  Now you can use following md2doc functions:
     
  * **convert(xs:string $input, xs:string $headline-element, xs:string $root-element)**  
    Transforms markdown string input into DocBook. Ideally used inside template that can match markdown text. Headline           element defines structure based on headlines. For example, if `$headline-element = 'chapter'`. all h1 headlines are taken     as chapter. Root element otherwise defines if whole document should be wrapped in root element like `<book>` or              `<article>`. This argument is optional.

    To be clear, headline element is defining component-level tag and root element is defining division-level tag of             DocBook. If you want to use some component-level tag like `article` as a root one, you can use this function like this:      `convert($input, '', 'article')`.

  * **convert(xs:string $input, xs:string $headline-element)**  
    Same as above but without defining root element. Warning, this function doesn't return well-formed document!

  * **read-file(xs:string $uri, xs:string $encoding)**  
    Attempts to read a file on path defined by $uri. If file can be located and has correct enconding as supplied by second      argument, function returns content of the file as a string. Otherwise, it shows error message. You can use this to supply     input for convert() functions.

  * **get-html(xs:string $input)**  
    This function simulates Markdown parsing into HTML. It creates same output as original parser by Mark Gruber written in      Perl. When talking about DocBook, you won't probably find usage for this function at all, but it can be used as a way how     to parse Markdown to HTML using XSLT 2.0.
    
  * **get-processor-info()**  
    Returns information such as product name and version of installed XSLT processor.
        
### 2. Using stylesheet to convert markdown documents ###

  Running with parameters and property options like `-it main-from-file`

###~~ 3. Running stylesheet over DocBook XML document ~~###

  ~~Markdown should be somehow identified, so stylesheet could recognize it.~~
