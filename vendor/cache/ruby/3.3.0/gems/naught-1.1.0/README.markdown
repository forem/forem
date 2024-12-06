[![Gem Version](https://badge.fury.io/rb/naught.svg)][gem]
[![Build Status](https://travis-ci.org/avdi/naught.svg?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/avdi/naught.svg)][gemnasium]
[![Code Climate](https://codeclimate.com/github/avdi/naught/badges/gpa.svg)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/avdi/naught/badge.svg?branch=master&service=github)][coveralls]
[![Inline docs](http://inch-ci.org/github/avdi/naught.svg?branch=master)][docs]

[gem]: https://rubygems.org/gems/naught
[travis]: https://travis-ci.org/avdi/naught
[gemnasium]: https://gemnasium.com/avdi/naught
[codeclimate]: https://codeclimate.com/github/avdi/naught
[coveralls]: https://coveralls.io/github/avdi/naught?branch=master
[docs]: http://inch-ci.org/github/avdi/naught

A quick intro to Naught
-------------------------

#### What's all this now then?

Naught is a toolkit for building [Null
Objects](http://en.wikipedia.org/wiki/Null_Object_pattern) in Ruby.

#### What's that supposed to mean?

Null Objects can make your code more
[confident](http://confidentruby.com).

Here's a method that's not very sure of itself.

```ruby
class Geordi
  def make_it_so(logger=nil)
    logger && logger.info("Reversing the flux phase capacitance!")
    logger && logger.info("Bounding a tachyon particle beam off of Data's cat!")
    logger && logger.warn("Warning, bogon levels are rising!")
  end
end
```

Now, observe as we give it a dash of confidence with the Null Object
pattern!

```ruby
class NullLogger
  def debug(*); end
  def info(*); end
  def warn(*); end
  def error(*); end
  def fatal(*); end
end

class Geordi
  def make_it_so(logger=NullLogger.new)
    logger.info "Reversing the flux phase capacitance!"
    logger.info "Bounding a tachyon particle beam off of Data's cat!"
    logger.warn "Warning, bogon levels are rising!"
  end
end
```

By providing a `NullLogger` which implements [some of] the `Logger`
interface as no-op methods, we've gotten rid of those unsightly `&&`
operators.

#### That was simple enough. Why do I need a library for it?

You don't! The Null Object pattern is a very simple one at its core.

#### And yet here we are…

Yes. While you don't *need* a Null Object library, this one offers some
conveniences you probably won't find elsewhere.

But there's an even more important reason I wrote this library. In the
immortal last words of James T. Kirk: "It was… *fun!*"

#### OK, so how do I use this thing?

Well, what would you like to do?

#### I dunno, gimme an object that responds to any message with nil

Sure thing!

```ruby
require 'naught'

NullObject = Naught.build

null = NullObject.new
null.foo                        # => nil
null.bar                        # => nil
```

#### That was… weird. What's with this "build" business?

Naught is a *toolkit* for building null object classes. It is not a
one-size-fits-all solution.

What else can I make for you?

#### How about a "black hole" null object that supports infinite chaining of methods?

OK.

```ruby
require 'naught'

BlackHole = Naught.build do |config|
  config.black_hole
end

null = BlackHole.new
null.foo                           # => <null>
null.foo.bar.baz                   # => <null>
null << "hello" << "world"         # => <null>
```

#### What's that "config" thing?

That's what you use to customize the generated class to your
liking. Internally, Naught uses the [Builder
Pattern](http://en.wikipedia.org/wiki/Builder_pattern) to make this work..

#### Whatever. What if I want a null object that has conversions to Integer, String, etc. using sensible conversions to "zero values"?

We can do that.

```ruby
require 'naught'

NullObject = Naught.build do |config|
  config.define_explicit_conversions
end

null = NullObject.new

null.to_s                          # => ""
null.to_i                          # => 0
null.to_f                          # => 0.0
null.to_a                          # => []
null.to_h                          # => {}
null.to_c                          # => (0+0i)
null.to_r                          # => (0/1)
```

#### Ah, but what about implicit conversions such as `#to_str`? Like what if I want a null object that implicitly splats the same way as an empty array?

Gotcha covered.

```ruby
require 'naught'

NullObject = Naught.build do |config|
  config.define_implicit_conversions
end

null = NullObject.new

null.to_str                     # => ""
null.to_ary                     # => []

a, b, c = []
a                               # => nil
b                               # => nil
c                               # => nil
x, y, z = null
x                               # => nil
y                               # => nil
z                               # => nil
```

#### How about a null object that only stubs out the methods from a specific class?

That's what `mimic` is for.

```ruby
require 'naught'

NullIO = Naught.build do |config|
  config.mimic IO
end

null_io = NullIO.new

null_io << "foo"                # => nil
null_io.readline                # => nil
null_io.foobar                  # =>
# ~> -:11:in `<main>': undefined method `foobar' for
#  <null:IO>:NullIO (NoMethodError)
```

There is also `impersonate` which takes `mimic` one step further. The
generated null class will be derived from the impersonated class. This
is handy when refitting legacy code that contains type checks.

```ruby
require 'naught'

NullIO = Naught.build do |config|
  config.impersonate IO
end

null_io = NullIO.new
IO === null_io                  # => true

case null_io
when IO
  puts "Yep, checks out!"
  null_io << "some output"
else
  raise "Hey, I expected an IO!"
end
# >> Yep, checks out!
```

#### My objects are unique and special snowflakes, with new methods added to them at runtime. How are you gonna mimic *that*, hotshot?

So long as you can create an object to serve as an example, Naught can copy the interface of that object (both the methods defined by its class, and its singleton methods).

```ruby
require "naught"
require "logging"

log = Logging.logger["test"]
log.info

NullLog = Naught.build do |config|
  config.mimic example: log
end

null_log = NullLog.new
null_log.info                  # => nil
```

#### What about predicate methods? You know, the ones that end with question marks? Shouldn't they return `false` instead of `nil`?

Sure, if you'd like.

```ruby
require 'naught'

NullObject = Naught.build do |config|
  config.predicates_return false
end

null = NullObject.new
null.foo                        # => nil
null.bar?                       # => false
null.nil?                       # => false
```

#### Alright smartypants. What if I want to add my own methods?

Not a problem, just define them in the `.build` block.

```ruby
require 'naught'

NullObject = Naught.build do |config|
  config.define_explicit_conversions
  config.predicates_return false
  def to_path
    "/dev/null"
  end

  # You can override methods generated by Naught
  def to_s
    "NOTHING TO SEE HERE MOVE ALONG"
  end

  def nil?
    true
  end
end

null = NullObject.new
null.to_path                    # => "/dev/null"
null.to_s                       # => "NOTHING TO SEE HERE MOVE ALONG"
null.nil?                       # => true
```

#### Got anything else up your sleeve?

Well, we can make the null class a singleton, since null objects
generally have no state.

```ruby
require 'naught'

NullObject = Naught.build do |config|
  config.singleton
end

null = NullObject.instance

null.__id__                     # => 17844080
NullObject.instance.__id__      # => 17844080
NullObject.new                  # =>
# ~> -:11:in `<main>': private method `new' called for
#  NullObject:Class (NoMethodError)
```

Speaking of null objects with state, we can also enable tracing. This is
handy for playing "where'd that null come from?!" Try doing *that* with
`nil`!

```ruby
require 'naught'

NullObject = Naught.build do |config|
  config.traceable
end

null = NullObject.new           # line 7

null.__file__                   # => "example.rb"
null.__line__                   # => 7
```

We can even conditionally enable either singleton mode (for production)
or tracing (for development). Here's an example of using the `$DEBUG`
global variable (set with the `-d` option to ruby) to choose which one.

```ruby
require 'naught'

NullObject = Naught.build do |config|
  if $DEBUG
    config.traceable
  else
    config.singleton
  end
end
```

The only caveat is that when swapping between singleton and
non-singleton implementations, you should be careful to always
instantiate your null objects with `NullObject.get`, not `.new` or
`.instance`. `.get` will work whether the class is implemented as a
singleton or not.

```ruby
NullObject.get                  # => <null>
```

#### And if I want to know legacy code better?

Naught can make a null object behave as a pebble object.

```ruby
require 'naught'

NullObject = Naught.build do |config|
  if $DEBUG
    config.pebble
  else
    config.black_hole
  end
end
```

Now you can pass the pebble object to your code and see which messages are sent to the pebble.

```ruby
null = NullObject.new

class MyConsumer < Struct.new(:producer)
  def consume
    producer.produce
  end
end

MyConsumer.new(null).consume
# >> produce() from consume
# => <null>
```

#### Are you done yet?

Just one more thing. For maximum convenience, Naught-generated null
classes also come with a full suite of conversion functions which can be
included into your classes.

```ruby
require 'naught'

NullObject = Naught.build

include NullObject::Conversions

# Convert nil to null objects. Everything else passes through.
Maybe(42)                       # => 42
Maybe(nil)                      # => <null>
Maybe(NullObject.get)           # => <null>
Maybe{ 42 }                     # => 42

# Insist on a non-null (or nil) value
Just(42)                        # => 42
Just(nil) rescue $!             # => #<ArgumentError: Null value: nil>
Just(NullObject.get) rescue $!  # => #<ArgumentError: Null value: <null>>

# nils and nulls become nulls. Everything else is rejected.
Null()                          # => <null>
Null(42) rescue $!              # => #<ArgumentError: 42 is not null!>
Null(nil)                       # => <null>
Null(NullObject.get)            # => <null>

# Convert nulls back to nils. Everything else passes through. Useful
# for preventing null objects from "leaking" into public API return
# values.
Actual(42)                      # => 42
Actual(nil)                     # => nil
Actual(NullObject.get)          # => nil
Actual { 42 }                   # => 42
```

Installation
--------------

``` {.example}
gem install naught
```

Requirements
--------------

-   Ruby

Contributing
--------------

-   Fork, branch, submit PR, blah blah blah. Don't forget tests.

Who's responsible
-------------------

Naught is by [Avdi Grimm](http://devblog.avdi.org/).

Prior Art
---------

This isn't the first Ruby Null Object library. Others to check out include:

 - [NullAndVoid](https://github.com/jfelchner/null_and_void)
 - [BlankSlate](https://github.com/saturnflyer/blank_slate)

The Book
--------

If you've read this far, you might be interested in the short ebook, [*Much Ado About Naught*](https://shiprise.dpdcart.com/cart/add?product_id=64334&method_id=66165), I (Avdi) wrote as I developed this library. It's a fun exploration of Ruby metaprogramming techniques as applied to writing a Ruby gem. You can [read the introduction here](http://devblog.avdi.org/introduction-to-much-ado-about-naught/).

Further reading
-----------------

-   [Null Object: Something for
    Nothing](http://www.two-sdg.demon.co.uk/curbralan/papers/europlop/NullObject.pdf)
    (PDF) by Kevlin Henney
-   [The Null Object
    Pattern](http://www.cs.oberlin.edu/~jwalker/refs/woolf.ps) (PS) by
    Bobby Woolf
-   [NullObject](http://www.c2.com/cgi/wiki?NullObject) on WikiWiki
-   [Null Object
    pattern](http://en.wikipedia.org/wiki/Null_Object_pattern) on
    Wikipedia
-   [Null Objects and
    Falsiness](http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/),
    by Avdi Grimm

Libraries Using Naught
-----------------------

-   [ActiveNull](https://github.com/Originate/active_null) Null Model support for ActiveRecord.
-   [Twitter](https://github.com/sferik/twitter) A Ruby interface to the Twitter API.
