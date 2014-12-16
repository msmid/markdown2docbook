# TEST MARKDOWN SHEET #

by Martin Smid

md2doc version 1.0.4

## LISTS ##

ul list:

* list item
+ list item with _inline_ element
- different marks

ol list:

   1.   number one item
   2.   number **two** item
   8.   marked as 8th item
   
nested structures:

* list item
  * nested ul list
  
    nested paragraph.
    
          nested codeblock!
          
    > nested blockquote
    
    ### nested header ###

* again list item
with lazy paragraph.

special case:

   * indended by three spaces
* no indend at all
   * again three spaces
   
## BLOCKQUOTES ##

> ## This is a header.
> 
> * list 1
> * list 2
> 
> Here's some example code:
> 
>     return shell_exec("echo $input | $markdown_script");   
>
> * * *

Lazy blockquote

> This is blockquote
and these two
are lazy lines

## HEADERS ##

Setext-style

Headline h1
===========

Headline h2
-----------

ATX-style

# headline 1
## headline 2 with trailing hashes ##
### headline 3
#### headline 4
##### headline 5
###### headline 6
########## Still headline 6

## RULERS ##

various combinations of five rulers

_ _ _ _ _ _ _ _

* * *
  
_______

-  -  -  - -

______________________________

## CODEBLOCKS ##

Four spaces indended codeblock

    This is codeblock with < and &
    another line

## PARAGRAPHS ##

This is para,
this whole,
is one para

but this is new para

## BLOCK HTML ##

<div>
  <table>
    <tr><td>Table inside div</td></tr>
  </table>
</div>

<div class="gotClass">on one line</div>

## CODESPANS ##

This is text with `code` in it.
Sometimes I want to add strong to it **`strong code`**.
Also I want to write about Markdown syntax `` code looks like `this` ``.

## INLINE HTML ##

Sometimes I need inline <cite>cite</cite>,
or image with attributes <img width="35px" src="img.jpg" alt="img"/>.
Weird but nested _<i>html<i/>_.

## HARDBREAKS ##

Well, I need to end text here  
and start over!

## SPANS ##

This is __strong__ and this is __not**.
Nested spans looks like ***this!***

## IMAGES AND ANCHORS ##

There is imaginative inline ![image](path/to/img "inline image"),
but here is referenced ![image][1].

Anchors are [similiar](www.vse.cz "inline anchor"),
really [similiar][2].

Try implicit emphasised link on _[Google][]_.

[1]: path/to/img "referenced img"
[2]: www.vse.cz "referenced anchor"
[Google]: www.google.com "google"

## AUTOMATIC LINKS ##

This is automatic <http://www.markdown2docbook.com>

## ESCAPING ##

I want to write file with underscores bg\_body\_out.png

How to treat <, & and >

## SPECIAL CASES ##

Asterisk * looks like [star*](path/to/star)

![*image*](img.png)

this is headline 2

* * *
-----

and this is one list

* * this is not nested

This text needs to have escaped dot \\.

I recommend upgrading to version
8. Oops, now this line is treated
as a sub-list.