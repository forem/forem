Sterile ![test](https://github.com/pbhogan/sterile/actions/workflows/test.yml/badge.svg)
=======

Sterilize your strings! Transliterate, generate slugs, smart format, strip tags, encode/decode entities and more.

Usage
-----

Sterile provides functionality both as class methods on the Sterile module and as extensions to the String class. Each function also has a "bang" version to replace the string in place.

    Sterile.transliterate("šţɽĩɳģ") # => "string"

    "šţɽĩɳģ".transliterate # => "string"

    str = "šţɽĩɳģ"
    str.transliterate!
    str == "string" # => true

Transliterate
-------------

Transliterate Unicode [and accented ASCII] characters to their plain-text ASCII equivalents. This is based on data from the stringex gem (https://github.com/rsl/stringex) which is in turn a port of Perl's Unidecode and ostensibly provides superior results to iconv. The optical conversion data is based on work by Eric Boehs at https://github.com/ericboehs/to_slug

    "šţɽĩɳģ".transliterate # => "string"

Passing an option of :optical => true will prefer optical mapping instead of more pedantic matches. The optical dataset is incomplete, but will fall back to the pedantic match if missing.

Smart Format
------------

Format text with proper "curly" quotes, m-dashes, copyright, trademark, etc.

    q{"He said, 'Away with you, Drake!'"}.smart_format
    # => “He said, ‘Away with you, Drake!’”

You can also use smart formatting with HTML:

    %q{"He said, <b>'Away with you, Drake!'</b>"}.smart_format_tags
    # => "&ldquo;He said, <b>&lsquo;Away with you, Drake!&rsquo;</b>&ldquo;"

Entities
--------

Turn Unicode characters into their HTML equivilents. If a valid HTML entity is not possible, it will create a numeric entity.

    q{“Economy Hits Bottom,” ran the headline}.encode_entities # => "&ldquo;Economy Hits Bottom,&rdquo; ran the headline"

Turn HTML entities into unicode characters:

    "&ldquo;Economy Hits Bottom,&rdquo; ran the headline".decode_entities # => "“Economy Hits Bottom,” ran the headline"

Titlecase
---------

Format text appropriately for titles. This method is much smarter than ActiveSupport's titlecase. The algorithm is based on work done by John Gruber et al (http://daringfireball.net/2008/08/title_case_update). It gets closer to the AP standard for title capitalization, including proper support for small words and handles a variety of edge cases.

	"Q&A with Steve Jobs: 'That's what happens in technology'".titlecase
	# => "Q&A With Steve Jobs: 'That's What Happens in Technology'"
	
	"Small word at end is nothing to be afraid of".titleize # alias for titlecase
	# => "Small Word at End Is Nothing to Be Afraid Of"

Strip Tags
----------

Remove HTML/XML tags from text. Also strips out comments, PHP and ERB style tags.

    'Visit our <a href="http://example.com">website!</a>'.strip_tags # => "Visit our website!"

Miscellaneous
-------------

Transliterate to ASCII, downcase and format for URL permalink/slug by stripping out all non-alphanumeric characters and replacing spaces with a delimiter (defaults to '-', configured by :delimiter option).

    "Hello World!".sluggerize # => "hello-world"
		"Hello World!".to_slug # => "hello-world"

Transliterate to ASCII and strip out any HTML/XML tags.

    "<b>nåsty</b>".sterilize # => "nasty"

Trim whitespace from start and end of string and remove any redundant whitespace in between.

    " Hello  world! ".transliterate # => "Hello world!"

Iterate over all text in between HTML/XML tags and yield text to a block, replace by what the block returns.

    "Only <i>uppercase</i> the <b>text</b> in this".gsub_tags { |t| t.upcase }

Iterate over all text in between HTML/XML tags and yield to a block.

    "Only <i>output</i> the <b>text</b> in this".scan_tags { |t| puts t }

Warning / To Do
---------------

All the *_tags functions are based on a regular expressions. Yes, I know this is [wrong](http://stackoverflow.com/questions/1732348/regex-match-open-tags-except-xhtml-self-contained-tags/1732454#1732454) and I plan to using a proper parser for it in the future.

Installation
------------

Install with RubyGems:

    gem install sterile

License
-------

Copyright (c) 2011 Patrick Hogan, released under the MIT License.
http://www.opensource.org/licenses/mit-license
