# Burrito Notes 
I think I need to redesign this plugin from the ground up, but first I need to 
organize my thoughts.

## GitHub Flavored Markdown 
Also known as GFM. This is what Burrito will attempt to support. See the spec
[here](https://github.github.com/gfm/).

## What are the different types of lines? 
There are header-like lines that start with a #. These can be called 
"independent lines" because they don't join with lines above or below. 

There are also bullet-like lines that don't join with lines above, but do with 
lines below. These are called "bottom only" lines. 

Finally, there are "normal lines" which wrap and join in any scenario.

## List 
This is the list of markdown symbols and what type of line they relate to.

### Independent Lines
* A thematic break (see GFM spec 4.1 for list)
* ATX Headings (0-3 spaces, 1-6 hashtags, a space)
* A setext heading underline
* A line that is all whitespace or blank.
* A fenced code block. The content of the fenced code block is also
  independent. Don't wrap code!
* All lines of a table

### Bottom Only Lines
* Block quote
* List Items

## Trailing Whitespace 
Keep it. This makes joining lines more intuitive when using backspace in Insert
Mode. 

## Regex
Burrito will use regex to determine what category each line falls in to. The
tokens that will be available are:
* All patterns are parsed as if they start with a ^
* $ for end of line
* {x} for amount of matches
* {x,y} for range of matches
* [] for multiple characters
* * for 0 or more of
* + for 1 or more of
* \ as an escape character

## Indent Behavior
Differences between an indent at the start of a paragraph and an indent because
of a list.
```
  Start of a paragraph.
The body continues down here.

* A bulleted list.
  The body continues down here.
```
