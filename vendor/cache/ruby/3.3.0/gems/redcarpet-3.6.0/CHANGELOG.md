# Changelog

## Version 3.6.0

* Avoid warnings running on Ruby 3.2+.

  Refs #721.

  *Jean Boussier*

* Match fence char and length when matching closing fence in fenced code blocks.

  Fixes #208.

  *Martin Cizek, Orchitech*

* Consider `<center>` as a block-level element.

  Refs #702.

  *momijizukamori*

* Properly provide a third argument to the `table_cell` callback indicating
  whether the current cell is part of the header or not.

  The previous implementation with two parameters is still supported.

  Fixes #604, Refs #605.

  *Mark Lambley*

* Fix anchor generation on titles with ampersands.

  Fixes #696.

## Version 3.5.1 (Security)

* Fix a security vulnerability using `:quote` in combination with the
  `:escape_html` option.

  Reported by *Johan Smits*.


## Version 3.5.0

* Avoid mutating the options hash passed to a render object.

  Refs #663.

  *Max Schwenk*

* Fix a segfault rendering quotes using `StripDown` and the `:quote`
  option.

  Fixes #639.

* Fix `warning: instance variable @options not initialized` when
  running under verbose mode (`-w`, `$VERBOSE = true`).

* Fix SmartyPants single quotes right after a link. For example:

  ~~~markdown
  [John](http://john.doe)'s cat
  ~~~

  Will now properly converts `'` to a right single quote (i.e. `’`).

  Fixes #624.

* Remove the `rel` and `rev` attributes from the output generated
  for footnotes as they don't pass the HTML 5 validation.

  Fixes #536.

* Automatically enable the `fenced_code_blocks` option passing a
  `HTML_TOC` object to the `Markdown` object's constructor since
  some languages rely on the sharp to comment code.

  Fixes #451.

* Allow passing `Range` objects to the `nesting_level` option to have
  a higher level of customization for table of contents:

  ~~~ruby
  Redcarpet::Render::HTML_TOC.new(nesting_level: 2..5)
  ~~~

  Fixes #519.

## Version 3.4.0

* Rely on djb2 hashing generating anchors with non-ASCII chars.

  Fix issue [#538](https://github.com/vmg/redcarpet/issues/538).

  *Alexey Kopytko*, *namusyaka*

* Added suppport for HTML 5 `details` and `summary` tags.

  Fix issue [#578](https://github.com/vmg/redcarpet/issues/578).

  *James Edwards-Jones*

* Multiple single quote pairs are parsed correctly with SmartyPants.

  Fix issue [#549](https://github.com/vmg/redcarpet/issues/549).

  *Jan Jędrychowski*

* Table headers don't require a minimum of three dashes anymore; a
  single one can be used for each row.

* Remove escaped entities from `HTML` render table of contents'
  ids to be consistent with the `HTML_TOC` render.

  Fix issue [#529](https://github.com/vmg/redcarpet/issues/529).

* Remove periods at the end of URLs when autolinking to make sure
  that links at the end of a sentence get properly generated.

  Fix issue [#465](https://github.com/vmg/redcarpet/issues/465).

* Expose the Markdown and rendering options through a `Hash` inside
  the `@options` instance variable for custom render objects.

* Avoid escaping ampersands in href links.

  *Nolan Evans*

## Version 3.3.4

* Fix `bufprintf` to correctly work on Windows MinGW-w64 so strings
  are properly written to the buffer.

  *Kenichi Saita*

* Fix the header anchor normalization by skipping non-ASCII chars
  and not calling tolower because this leads to invalid UTF-8 byte
  sequences in the HTML output. (tolower is not locale-aware)

  *Clemens Gruber*

## Version 3.3.3

* Fix a memory leak instantiating a `Redcarpet::Render::Base` object.

  *Oleg Dashevskii*

* Fix the `StripDown` renderer to handle the `:highlight` option.

  *Itay Grudev*

* The `StripDown` renderer handles tables if the `tables` extension is
  enabled.

  *amnesia7*

* Fix Smarty Pants to avoid fraction conversions when there are several
  numbers separated with slashes (e.g. for a date).

  *Sam Saffron*

## Version 3.3.2

* Fix a potential security issue in the HTML renderer
  (Thanks to Giancarlo Canales Barreto for the heads up)

## Version 3.3.1

* Include the `Redcarpet::CLI`'s file in the gemspec to make it
  available when downloading.

## Version 3.3.0

* Fix the stripping of surrounding characters that should be removed
  during anchor generation.

* Provide a `Redcarpet::CLI` class to create custom binary files.

  Relying on Ruby's OptionParser, it's now straightforward to add new
  options, rely on custom render objects or handle differently the
  rendering of the provided files.

* Undeprecate the compatibility layer for the old RedCloth API.

  This layer actually ease the support of libraries supporting different
  Markdown processors.

* Strip out `style` tags at the HTML-block rendering level when the
  `:no_styles` options is enabled ; previously they were only removed
  inside paragraphs.

* Avoid parsing images when the given URL isn't safe and the
  `:safe_links_only` option is enabled.

  *Alex Serban*

* Avoid parsing references inside fenced code blocks so they are
  now kept in the code snippet.

  *David Waller*

* Avoid escaping table-of-contents' headers by default. A new
  `:escape_html` option is now available for the `HTML_TOC` object
  if there are security concerns.

* Add the `lang-` prefix in front of the language's name when using
  `:prettify` along with `:fenced_code_blocks`.

* Non-alphanumeric chars are now stripped out from generated anchors
  (along the lines of Active Support's `#parameterize` method).

## Version 3.2.3

* Avoid rewinding content of a previous inline when autolinking is
  enabled.

  *Daniel LeCheminant*

* Fix escaping of forward slashes with the `Safe` render object (add a
  missing semi-colon).

## Version 3.2.2

* Consider `script` as a block-level element so it doesn't get included
  inside a paragraph.

## Version 3.2.1

* Load `RedcarpetCompat` when requiring Redcarpet for the sake of
  backward compatibility.

  *Loren Segal*

## Version 3.2.0

* Add a `Safe` renderer to deal with users' input. The `escape_html`
  and `safe_links_only` options are turned on by default.

  Moreover, the `block_code` callback removes the tag's class since
  the user can basically set anything with the vanilla one.

  *Robin Dupret*

* HTML5 block-level tags are now recognized

  *silverhammermba*

* The `StripDown` render object now displays the URL of links
  along with the text.

  *Robin Dupret*

* The RedCloth API compatibility layer is now deprecated.

  *Robin Dupret*

* A hyphen and an equal should not be converted to heading.

  *namusyaka*

* Fix emphasis character escape sequence detection while mid-emphasis.

  *jcheatham*

* Add `=` to the whitelist of escaped chars so it can be used inside
  highlighted snippets.

  *jcheatham*

* Convert trailing single quotes to curly quotes. For example,
  `Road Trippin'` now converts to `Road Trippin’`.

  *Kevin Chen*

* Allow in-page links (e.g. `[headline](#headline)`) when `:safe_links_only` is set.

  *jomo*

* Enable emphasis inside of sentences in multi-byte languages when
  `:no_intra_emphasis` is set.

  *Chun-wei Kuo*

* Avoid making `:no_intra_emphasis` only match spaces. This allows
  using emphasizes inside quotes when the option is enabled for
  instance.

  *Jason Webb* and *BJ Homer*

* The StripDown renderer handles image tags now.

## Version 3.1.2

* Remove the yielding of anchors in the `header` callback. This was
  a breaking change between 3.0 and 3.1 as the method's arity changed.

## Version 3.1.1

* Fix a segfault when parsing text with headers.

## Version 3.1.0

* Yield the anchor of the headers

  Using the `header` callback, it's now possible to get access to the
  humanized generated id to easily keep tracking of the tree of headers
  or simply handle the duplicate values easily.

  Since the `HTML_TOC` and `HTML` objects both have this callback, it's
  advisable to define a module and mix it in these objects to avoid
  code duplication.

  *Robin Dupret*

* Allow using tabs between a reference's colon and its link

  Fix issue [#337](https://github.com/vmg/redcarpet/issues/337)

  *Juan Guerrero*

* Make ordered lists preceded by paragraph parsed with `:lax_spacing`

  Previously, enabling the `:lax_spacing` option, if a paragraph was
  followed by an ordered list it was unparsed and was part of the
  paragraph but this is no more the case.

  *Robin Dupret*

* Feed the gemspec into ExtensionTask so that we can pre-compile.
  ie. `rake native gem`

  *Todd Edwards*

* Revert lax indent of less than 4 characters after list items

  Follow the standard to detect when new paragraph is outside last item.
  Fixes [issue #111](https://github.com/vmg/redcarpet/issues/111).

  *Eric Bréchemier*

* Fix code blocks' classes when using Google code prettify

  When using the the `:prettify` option and specifying the
  language name, the generated code block's class had a missing
  space.

  *Simonini*

* Add `-v`/`--version` and `-h` flags to commandline redcarpet

  *Lukas Stabe*

* Add optional quote support through the `:quote` option. Render
  quotations marks to `q` HTML tag.

  This is a `"quote"`.

  *Anatol Broder*

* Ensure inline markup in titles is correctly stripped when generating
  headers' anchor.

  *Robin Dupret*

* Revert the unescaping behavior on comments

  This behavior doesn't follow the conformance suite.

  *Robin Dupret*

* Add optional footnotes support

  Add PHP-Markdown style footnotes through the `:footnotes` option.

  *Ben Dolman, Adam Florin, microjo, brief*

* Enable GitHub style anchors for headers

  Passing the `with_toc_data` option to a `HTML` render object now
  generates GitHub style anchors.

  *Matt Rogers*

* Allow to set a maximum rendering level for HTML_TOC

  Allow the user to pass a `nesting_level` option when instantiating a
  new HTML_TOC render object in order to limit the nesting level in the
  generated table of content. For example:

  ~~~ruby
  Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC.new(nesting_level: 2))
  ~~~

  *Robin Dupret*

## Version 3.0.0

* Remove support for Ruby 1.8.x *Matt Rogers & Robin Dupret*

* Avoid escaping for HTML comments *Robin Dupret*

* Make emphasis wrapped inside parenthesis parsed *Robin Dupret*

* Remove the Sundown submodule *Robin Dupret*

* Fix FTP uris identified as emails *Robin Dupret*

* Add optional highlight support *Sam Soffes*

  This is `==highlighted==`.

* Ensure nested parenthesis are handled into links *Robin Dupret*

* Ensure nested code spans put in emphasis work correctly *Robin Dupret*

## Version 2.3.0

* Add a `:disable_indented_code_blocks` option *Dmitriy Kiriyenko*

* Fix issue [#57](https://github.com/vmg/redcarpet/issues/57) *Mike Morearty*

* Ensure new lines characters are inserted when using the StripDown
render. *Robin Dupret*

* Mark all symbols as hidden except the main entry point *Tom Hughes*

  This avoids conflicts with other gems that may have some of the
  same symbols, such as escape_utils which also uses houdini.

* Remove unnecessary function pointer *Sam Soffes*

* Add optional underline support *Sam Soffes*

  This is `*italic*` and this is `_underline_` when enabled.

* Test that links with quotes work *Michael Grosser*

* Adding a prettyprint class for google-code-prettify *Joel Rosenberg*

* Remove unused C macros *Matt Rogers*

* Remove 'extern' definition for Init_redcarpet_rndr() *Matt Rogers*

* Remove Gemfile.lock from the gemspec *Matt Rogers*

* Removed extra unused test statement. *Slipp D. Thompson*

* Use test-unit gem to get some red/green output when running tests
*Michael Grosser*

* Remove a deprecation warning and update Gemfile.lock *Robin Dupret*

* Added contributing file *Brent Beer*

* For tests for libxml2 > 2.8 *strzibny*

* SmartyPants: Preserve single `backticks` in HTML *Mike Morearty*

  When SmartyPants is processing HTML, single `backticks` should  be left
  intact. Previously they were being deleted.

* Removed and ignored Gemfile.lock *Ryan McGeary*

* Added support for org-table syntax *Ryan McGeary*

  Adds support for using a plus (+) as an intersection character instead of
  requiring pipes (|). The emacs org-mode table syntax automatically manages
  ascii tables, but uses pluses for line intersections.

* Ignore /tmp directory *Ryan McGeary*

* Add redcarpet_ prefix for `stack_*` functions *Kenta Murata*

* Mark any html_attributes has held by a renderer as used *Tom Hughes*

* Add Rubinius to the list of tested implementations *Gibheer*

* Add a changelog file
