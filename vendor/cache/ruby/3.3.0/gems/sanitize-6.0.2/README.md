Sanitize
========

Sanitize is an allowlist-based HTML and CSS sanitizer. It removes all HTML
and/or CSS from a string except the elements, attributes, and properties you
choose to allow.

Using a simple configuration syntax, you can tell Sanitize to allow certain HTML
elements, certain attributes within those elements, and even certain URL
protocols within attributes that contain URLs. You can also allow specific CSS
properties, @ rules, and URL protocols in elements or attributes containing CSS.
Any HTML or CSS that you don't explicitly allow will be removed.

Sanitize is based on the [Nokogiri HTML5 parser][nokogiri], which parses HTML
the same way modern browsers do, and [Crass][crass], which parses CSS the same
way modern browsers do. As long as your allowlist config only allows safe markup
and CSS, even the most malformed or malicious input will be transformed into
safe output.

[![Gem Version](https://badge.fury.io/rb/sanitize.svg)](http://badge.fury.io/rb/sanitize)
[![Tests](https://github.com/rgrove/sanitize/workflows/Tests/badge.svg)](https://github.com/rgrove/sanitize/actions?query=workflow%3ATests)

[crass]:https://github.com/rgrove/crass
[nokogiri]:https://github.com/sparklemotion/nokogiri

Links
-----

* [Home](https://github.com/rgrove/sanitize/)
* [API Docs](https://rubydoc.info/github/rgrove/sanitize/Sanitize)
* [Issues](https://github.com/rgrove/sanitize/issues)
* [Release History](https://github.com/rgrove/sanitize/releases)
* [Online Demo](https://sanitize-web.fly.dev/)

Installation
-------------

```
gem install sanitize
```

Quick Start
-----------

```ruby
require 'sanitize'

# Clean up an HTML fragment using Sanitize's permissive but safe Relaxed config.
# This also sanitizes any CSS in `<style>` elements or `style` attributes.
Sanitize.fragment(html, Sanitize::Config::RELAXED)

# Clean up an HTML document using the Relaxed config.
Sanitize.document(html, Sanitize::Config::RELAXED)

# Clean up a standalone CSS stylesheet using the Relaxed config.
Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED)

# Clean up some CSS properties using the Relaxed config.
Sanitize::CSS.properties(css, Sanitize::Config::RELAXED)
```

Usage
-----

Sanitize can sanitize the following types of input:

* HTML fragments
* HTML documents
* CSS stylesheets inside HTML `<style>` elements
* CSS properties inside HTML `style` attributes
* Standalone CSS stylesheets
* Standalone CSS properties

> **Warning**
>
> Sanitize cannot fully sanitize the contents of `<math>` or `<svg>` elements. MathML and SVG elements are [foreign elements](https://html.spec.whatwg.org/multipage/syntax.html#foreign-elements) that don't follow normal HTML parsing rules.
>
> By default, Sanitize will remove all MathML and SVG elements. If you add MathML or SVG elements to a custom element allowlist, you may create a security vulnerability in your application.

### HTML Fragments

A fragment is a snippet of HTML that doesn't contain a root-level `<html>`
element.

If you don't specify any configuration options, Sanitize will use its strictest
settings by default, which means it will strip all HTML and leave only safe text
behind.

```ruby
html = '<b><a href="http://foo.com/">foo</a></b><img src="bar.jpg">'
Sanitize.fragment(html)
# => 'foo'
```

To keep certain elements, add them to the element allowlist.

```ruby
Sanitize.fragment(html, :elements => ['b'])
# => '<b>foo</b>'
```

### HTML Documents

When sanitizing a document, the `<html>` element must be allowlisted. You can
also set `:allow_doctype` to `true` to allow well-formed document type
definitions.

```ruby
html = %[
  <!DOCTYPE html>
  <html>
    <b><a href="http://foo.com/">foo</a></b><img src="bar.jpg">
  </html>
]

Sanitize.document(html,
  :allow_doctype => true,
  :elements      => ['html']
)
# => %[
#   <!DOCTYPE html>
#   <html>foo
#
#   </html>
# ]
```

### CSS in HTML

To sanitize CSS in an HTML fragment or document, first allowlist the `<style>`
element and/or the `style` attribute. Then allowlist the CSS properties,
@ rules, and URL protocols you wish to allow. You can also choose whether to
allow CSS comments or browser compatibility hacks.

```ruby
html = %[
  <style>
    div { color: green; width: 1024px; }
  </style>

  <div style="height: 100px; width: 100px;"></div>
  <p>hello!</p>
]

Sanitize.fragment(html,
  :elements   => ['div', 'style'],
  :attributes => {'div' => ['style']},

  :css => {
    :properties => ['width']
  }
)
#=> %[
#   <style>
#     div {  width: 1024px; }
#   </style>
#
#   <div style=" width: 100px;"></div>
#   hello!
# ]
```

### Standalone CSS

Sanitize will happily clean up a standalone CSS stylesheet or property string
without needing to invoke the HTML parser.

```ruby
css = %[
  @import url(evil.css);

  a { text-decoration: none; }

  a:hover {
    left: expression(alert('xss!'));
    text-decoration: underline;
  }
]

Sanitize::CSS.stylesheet(css, Sanitize::Config::RELAXED)
# => %[
#
#
#
#   a { text-decoration: none; }
#
#   a:hover {
#
#     text-decoration: underline;
#   }
# ]

Sanitize::CSS.properties(%[
  left: expression(alert('xss!'));
  text-decoration: underline;
], Sanitize::Config::RELAXED)
# => %[
#
#   text-decoration: underline;
# ]

```

Configuration
-------------

In addition to the ultra-safe default settings, Sanitize comes with three other
built-in configurations that you can use out of the box or adapt to meet your
needs.

### Sanitize::Config::RESTRICTED

Allows only very simple inline markup. No links, images, or block elements.

```ruby
Sanitize.fragment(html, Sanitize::Config::RESTRICTED)
# => '<b>foo</b>'
```

### Sanitize::Config::BASIC

Allows a variety of markup including formatting elements, links, and lists.

Images and tables are not allowed, links are limited to FTP, HTTP, HTTPS, and
mailto protocols, and a `rel="nofollow"` attribute is added to all links to
mitigate SEO spam.

```ruby
Sanitize.fragment(html, Sanitize::Config::BASIC)
# => '<b><a href="http://foo.com/" rel="nofollow">foo</a></b>'
```

### Sanitize::Config::RELAXED

Allows an even wider variety of markup, including images and tables, as well as
safe CSS. Links are still limited to FTP, HTTP, HTTPS, and mailto protocols,
while images are limited to HTTP and HTTPS. In this mode, `rel="nofollow"` is
not added to links.

```ruby
Sanitize.fragment(html, Sanitize::Config::RELAXED)
# => '<b><a href="http://foo.com/">foo</a></b><img src="bar.jpg">'
```

### Custom Configuration

If the built-in modes don't meet your needs, you can easily specify a custom
configuration:

```ruby
Sanitize.fragment(html,
  :elements => ['a', 'span'],

  :attributes => {
    'a'    => ['href', 'title'],
    'span' => ['class']
  },

  :protocols => {
    'a' => {'href' => ['http', 'https', 'mailto']}
  }
)
```

You can also start with one of Sanitize's built-in configurations and then
customize it to meet your needs.

The built-in configs are deeply frozen to prevent people from modifying them
(either accidentally or maliciously). To customize a built-in config, create a
new copy using `Sanitize::Config.merge()`, like so:

```ruby
# Create a customized copy of the Basic config, adding <div> and <table> to the
# existing allowlisted elements.
Sanitize.fragment(html, Sanitize::Config.merge(Sanitize::Config::BASIC,
  :elements        => Sanitize::Config::BASIC[:elements] + ['div', 'table'],
  :remove_contents => true
))
```

The example above adds the `<div>` and `<table>` elements to a copy of the
existing list of elements in `Sanitize::Config::BASIC`. If you instead want to
completely overwrite the elements array with your own, you can omit the `+`
operation:

```ruby
# Overwrite :elements instead of creating a copy with new entries.
Sanitize.fragment(html, Sanitize::Config.merge(Sanitize::Config::BASIC,
  :elements        => ['div', 'table'],
  :remove_contents => true
))
```

### Config Settings

#### :add_attributes (Hash)

Attributes to add to specific elements. If the attribute already exists, it will
be replaced with the value specified here. Specify all element names and
attributes in lowercase.

```ruby
:add_attributes => {
  'a' => {'rel' => 'nofollow'}
}
```

#### :allow_comments (boolean)

Whether or not to allow HTML comments. Allowing comments is strongly
discouraged, since IE allows script execution within conditional comments. The
default value is `false`.

#### :allow_doctype (boolean)

Whether or not to allow well-formed HTML doctype declarations such as "<!DOCTYPE
html>" when sanitizing a document. This setting is ignored when sanitizing
fragments. The default value is `false`.

#### :attributes (Hash)

Attributes to allow on specific elements. Specify all element names and
attributes in lowercase.

```ruby
:attributes => {
  'a'          => ['href', 'title'],
  'blockquote' => ['cite'],
  'img'        => ['alt', 'src', 'title']
}
```

If you'd like to allow certain attributes on all elements, use the symbol `:all`
instead of an element name.

```ruby
# Allow the class attribute on all elements.
:attributes => {
  :all => ['class'],
  'a'  => ['href', 'title']
}
```

To allow arbitrary HTML5 `data-*` attributes, use the symbol `:data` in place of
an attribute name.

```ruby
# Allow arbitrary HTML5 data-* attributes on <div> elements.
:attributes => {
  'div' => [:data]
}
```

#### :css (Hash)

Hash of the following CSS config settings to be used when sanitizing CSS (either
standalone or embedded in HTML).

##### :css => :allow_comments (boolean)

Whether or not to allow CSS comments. The default value is `false`.

##### :css => :allow_hacks (boolean)

Whether or not to allow browser compatibility hacks such as the IE `*` and `_`
hacks. These are generally harmless, but technically result in invalid CSS. The
default is `false`.

##### :css => :at_rules (Array or Set)

Names of CSS [at-rules][at-rules] to allow that may not have associated blocks,
such as `import` or `charset`. Names should be specified in lowercase.

[at-rules]:https://developer.mozilla.org/en-US/docs/Web/CSS/At-rule

##### :css => :at_rules_with_properties (Array or Set)

Names of CSS [at-rules][at-rules] to allow that may have associated blocks
containing CSS properties. At-rules like `font-face` and `page` fall into this
category. Names should be specified in lowercase.

##### :css => :at_rules_with_styles (Array or Set)

Names of CSS [at-rules][at-rules] to allow that may have associated blocks
containing style rules. At-rules like `media` and `keyframes` fall into this
category. Names should be specified in lowercase.

##### :css => :import_url_validator

This is a `Proc` (or other callable object) that will be called and passed
the URL specified for any `@import` [at-rules][at-rules].

You can use this to limit what can be imported, for example something
like the following to limit `@import` to Google Fonts URLs:

```ruby
Proc.new { |url| url.start_with?("https://fonts.googleapis.com") }
```

##### :css => :properties (Array or Set)

List of CSS property names to allow. Names should be specified in lowercase.

##### :css => :protocols (Array or Set)

URL protocols to allow in CSS URLs. Should be specified in lowercase.

If you'd like to allow the use of relative URLs which don't have a protocol,
include the symbol `:relative` in the protocol array.

#### :elements (Array or Set)

Array of HTML element names to allow. Specify all names in lowercase. Any
elements not in this array will be removed.

```ruby
:elements => %w[
  a abbr b blockquote br cite code dd dfn dl dt em i kbd li mark ol p pre
  q s samp small strike strong sub sup time u ul var
]
```

> **Warning**
>
> Sanitize cannot fully sanitize the contents of `<math>` or `<svg>` elements. MathML and SVG elements are [foreign elements](https://html.spec.whatwg.org/multipage/syntax.html#foreign-elements) that don't follow normal HTML parsing rules.
>
> By default, Sanitize will remove all MathML and SVG elements. If you add MathML or SVG elements to a custom element allowlist, you must assume that any content inside them will be allowed, even if that content would otherwise be removed or escaped by Sanitize. This may create a security vulnerability in your application.

> **Note**
>
> Sanitize always removes `<noscript>` elements and their contents, even if `noscript` is in the allowlist.
>
> This is because a `<noscript>` element's content is parsed differently in browsers depending on whether or not scripting is enabled. Since Nokogiri doesn't support scripting, it always parses `<noscript>` elements as if scripting is disabled. This results in edge cases where it's not possible to reliably sanitize the contents of a `<noscript>` element because Nokogiri can't fully replicate the parsing behavior of a scripting-enabled browser.

#### :parser_options (Hash)

[Parsing options](https://github.com/rubys/nokogumbo/tree/master#parsing-options) to be supplied to `nokogumbo`.

```ruby
:parser_options => {
  max_errors: -1,
  max_tree_depth: -1
}
```

#### :protocols (Hash)

URL protocols to allow in specific attributes. If an attribute is listed here
and contains a protocol other than those specified (or if it contains no
protocol at all), it will be removed.

```ruby
:protocols => {
  'a'   => {'href' => ['ftp', 'http', 'https', 'mailto']},
  'img' => {'src'  => ['http', 'https']}
}
```

If you'd like to allow the use of relative URLs which don't have a protocol,
include the symbol `:relative` in the protocol array:

```ruby
:protocols => {
  'a' => {'href' => ['http', 'https', :relative]}
}
```

#### :remove_contents (boolean or Array or Set)

If this is `true`, Sanitize will remove the contents of any non-allowlisted
elements in addition to the elements themselves. By default, Sanitize leaves the
safe parts of an element's contents behind when the element is removed.

If this is an Array or Set of element names, then only the contents of the
specified elements (when filtered) will be removed, and the contents of all
other filtered elements will be left behind.

The default value is `%w[iframe math noembed noframes noscript plaintext script style svg xmp]`.

#### :transformers (Array or callable)

Custom HTML transformer or array of custom transformers. See the Transformers
section below for details.

#### :whitespace_elements (Hash)

Hash of element names which, when removed, should have their contents surrounded
by whitespace to preserve readability.

Each element name is a key pointing to another Hash, which provides the specific
whitespace that should be inserted `:before` and `:after` the removed element's
position. The `:after` value will only be inserted if the removed element has
children, in which case it will be inserted after those children.

```ruby
:whitespace_elements => {
  'br'  => { :before => "\n", :after => "" },
  'div' => { :before => "\n", :after => "\n" },
  'p'   => { :before => "\n", :after => "\n" }
}
```

The default elements with whitespace added before and after are:

```
address article aside blockquote br dd div dl dt
footer h1 h2 h3 h4 h5 h6 header hgroup hr li nav
ol p pre section ul

```

## Transformers

Transformers allow you to filter and modify HTML nodes using your own custom
logic, on top of (or instead of) Sanitize's core filter. A transformer is any
object that responds to `call()` (such as a lambda or proc).

To use one or more transformers, pass them to the `:transformers` config
setting. You may pass a single transformer or an array of transformers.

```ruby
Sanitize.fragment(html, :transformers => [
  transformer_one,
  transformer_two
])
```

### Input

Each transformer's `call()` method will be called once for each node in the HTML
(including elements, text nodes, comments, etc.), and will receive as an
argument a Hash that contains the following items:

  * **:config** - The current Sanitize configuration Hash.

  * **:is_allowlisted** - `true` if the current node has been allowlisted by a
    previous transformer, `false` otherwise. It's generally bad form to remove
    a node that a previous transformer has allowlisted.

  * **:node** - A `Nokogiri::XML::Node` object representing an HTML node. The
    node may be an element, a text node, a comment, a CDATA node, or a document
    fragment. Use Nokogiri's inspection methods (`element?`, `text?`, etc.) to
    selectively ignore node types you aren't interested in.

  * **:node_allowlist** - Set of `Nokogiri::XML::Node` objects in the current
    document that have been allowlisted by previous transformers, if any. It's
    generally bad form to remove a node that a previous transformer has
    allowlisted.

  * **:node_name** - The name of the current HTML node, always lowercase (e.g.
    "div" or "span"). For non-element nodes, the name will be something like
    "text", "comment", "#cdata-section", "#document-fragment", etc.

### Output

A transformer doesn't have to return anything, but may optionally return a Hash,
which may contain the following items:

  * **:node_allowlist** -  Array or Set of specific `Nokogiri::XML::Node`
    objects to add to the document's allowlist, bypassing the current Sanitize
    config. These specific nodes and all their attributes will be allowlisted,
    but their children will not be.

If a transformer returns anything other than a Hash, the return value will be
ignored.

### Processing

Each transformer has full access to the `Nokogiri::XML::Node` that's passed into
it and to the rest of the document via the node's `document()` method. Any
changes made to the current node or to the document will be reflected instantly
in the document and passed on to subsequently called transformers and to
Sanitize itself. A transformer may even call Sanitize internally to perform
custom sanitization if needed.

Nodes are passed into transformers in the order in which they're traversed.
Sanitize performs top-down traversal, meaning that nodes are traversed in the
same order you'd read them in the HTML, starting at the top node, then its first
child, and so on.

```ruby
html = %[
  <header>
    <span>
      <strong>foo</strong>
    </span>
    <p>bar</p>
  </header>

  <footer></footer>
]

transformer = lambda do |env|
  puts env[:node_name] if env[:node].element?
end

# Prints "header", "span", "strong", "p", "footer".
Sanitize.fragment(html, :transformers => transformer)
```

Transformers have a tremendous amount of power, including the power to
completely bypass Sanitize's built-in filtering. Be careful! Your safety is in
your own hands.

### Example: Transformer to allow image URLs by domain

The following example demonstrates how to remove image elements unless they use
a relative URL or are hosted on a specific domain. It assumes that the `<img>`
element and its `src` attribute are already allowlisted.

```ruby
require 'uri'

image_allowlist_transformer = lambda do |env|
  # Ignore everything except <img> elements.
  return unless env[:node_name] == 'img'

  node      = env[:node]
  image_uri = URI.parse(node['src'])

  # Only allow relative URLs or URLs with the example.com domain. The
  # image_uri.host.nil? check ensures that protocol-relative URLs like
  # "//evil.com/foo.jpg".
  unless image_uri.host == 'example.com' || (image_uri.host.nil? && image_uri.relative?)
    node.unlink # `Nokogiri::XML::Node#unlink` removes a node from the document
  end
end
```

### Example: Transformer to allow YouTube video embeds

The following example demonstrates how to create a transformer that will safely
allow valid YouTube video embeds without having to allow other kinds of embedded
content, which would be the case if you tried to do this by just allowing all
`<iframe>` elements:

```ruby
youtube_transformer = lambda do |env|
  node      = env[:node]
  node_name = env[:node_name]

  # Don't continue if this node is already allowlisted or is not an element.
  return if env[:is_allowlisted] || !node.element?

  # Don't continue unless the node is an iframe.
  return unless node_name == 'iframe'

  # Verify that the video URL is actually a valid YouTube video URL.
  return unless node['src'] =~ %r|\A(?:https?:)?//(?:www\.)?youtube(?:-nocookie)?\.com/|

  # We're now certain that this is a YouTube embed, but we still need to run
  # it through a special Sanitize step to ensure that no unwanted elements or
  # attributes that don't belong in a YouTube embed can sneak in.
  Sanitize.node!(node, {
    :elements => %w[iframe],

    :attributes => {
      'iframe'  => %w[allowfullscreen frameborder height src width]
    }
  })

  # Now that we're sure that this is a valid YouTube embed and that there are
  # no unwanted elements or attributes hidden inside it, we can tell Sanitize
  # to allowlist the current node.
  {:node_allowlist => [node]}
end

html = %[
<iframe width="420" height="315" src="//www.youtube.com/embed/dQw4w9WgXcQ"
    frameborder="0" allowfullscreen></iframe>
]

Sanitize.fragment(html, :transformers => youtube_transformer)
# => '<iframe width="420" height="315" src="//www.youtube.com/embed/dQw4w9WgXcQ" frameborder="0" allowfullscreen=""></iframe>'
```
