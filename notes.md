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

There is also another type of bullet lines, which are the lines below the
actual bullet. For example:
```
* This is the first line of the bullet
  But it still continues down here
```
These are called "top only" lines. Additionally, top only lines maintain the
same indentation level as the original bullet line.

Finally, there are "normal lines" which wrap and join in any scenario.

## List
This is the list of markdown symbols and what type of line they relate to.

### Independent Lines
* A thematic break (see GFM spec 4.1 for list)
* ATX Headings (0-3 spaces, 1-6 hashtags, a space)
* A setext heading underline (although it can be interpreted as a thematic
  break)
* A line that is all whitespace or blank.
* An indented code block
* A fenced code block. The content of the fenced code block is also
  independent. Don't wrap code!
* All lines of a table

### Bottom Only Lines
* Any line that starts with whitespace
* List Items

### Top Only Lines
* Lines after a list item line

### Block Quotes
Block quotes are special because they behave as normal lines, but must insert
a `>` at the start of every line.


## Trailing Whitespace
Get rid of it
