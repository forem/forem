# XPath

XPath is a Ruby DSL around a subset of XPath 1.0. Its primary purpose is to
facilitate writing complex XPath queries from Ruby code.

[![Gem Version](https://badge.fury.io/rb/xpath.png)](http://badge.fury.io/rb/xpath)
[![Build Status](https://secure.travis-ci.org/teamcapybara/xpath.png?branch=master)](http://travis-ci.org/teamcapybara/xpath)

## Generating expressions

To create quick, one-off expressions, `XPath.generate` can be used:

``` ruby
XPath.generate { |x| x.descendant(:ul)[x.attr(:id) == 'foo'] }
```

You can also call expression methods directly on the `XPath` module:

``` ruby
XPath.descendant(:ul)[XPath.attr(:id) == 'foo']
```

However for more complex expressions, it is probably more convenient to include
the `XPath` module into your own class or module:

``` ruby
module MyXPaths
  include XPath

  def foo_ul
    descendant(:ul)[attr(:id) == 'foo']
  end

  def password_field(id)
    descendant(:input)[attr(:type) == 'password'][attr(:id) == id]
  end
end
```

Both ways return an `XPath::Expression` instance, which can be further
modified. To convert the expression to a string, just call `#to_s` on it. All
available expressions are defined in `XPath::DSL`.

## String, Hashes and Symbols

When you send a string as an argument to any XPath function, XPath assumes this
to be a string literal. On the other hand if you send in Symbol, XPath assumes
this to be an XPath literal. Thus the following two statements are not
equivalent:

``` ruby
XPath.descendant(:p)[XPath.attr(:id) == 'foo']
XPath.descendant(:p)[XPath.attr(:id) == :foo]
```

These are the XPath expressions that these would be translated to:

```
.//p[@id = 'foo']
.//p[@id = foo]
```

The second expression would match any p tag whose id attribute matches a 'foo'
tag it contains. Most likely this is not what you want.

In fact anything other than a String is treated as a literal. Thus the
following works as expected:

``` ruby
XPath.descendant(:p)[1]
```

Keep in mind that XPath is 1-indexed and not 0-indexed like most other
programming languages, including Ruby.

## License

See [LICENSE](LICENSE).
