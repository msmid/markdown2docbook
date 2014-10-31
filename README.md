markdown2docbook
================

Conversion tool for transforming markdown formatted text files to valid DocBook documents. Project is based on XSLT 2.0 technology.

XSL is developed under Saxon XSLT processor. See below why
 
   * better regex support than native XPath specification (using flag `!` for java regex)
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

### 1. Including md2doc stylesheet in another stylesheet ###
      
  Let's say you have your own xsl stylesheet and you want to use certain md2doc functions.
  There is nothing easier. Use `<xsl:include>` element. Don't forget about namespace! Be sure to add md2doc URI                `http://www.markdown2docbook.com/ns/markdown2docbook` between other namespace declarations. Example:

    <xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
         xmlns:md2doc="http://www.markdown2docbook.com/ns/md2doc"> ...

  Now you can use md2doc functions:
     
  * main($input) - Transforms markdown string input into DocBook nodes
  * get-html($input) - Same as main($input) function but this returns only HTML nodes
        
### 2. Running stylesheet over DocBook XML document ###
   
### 3. Using stylesheet to convert markdown documents ###
