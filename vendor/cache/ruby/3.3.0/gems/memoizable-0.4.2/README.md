# Memoizable

[![Gem Version](http://img.shields.io/gem/v/memoizable.svg)][gem]
[![Build Status](http://img.shields.io/travis/dkubb/memoizable.svg)][travis]
[![Dependency Status](http://img.shields.io/gemnasium/dkubb/memoizable.svg)][gemnasium]
[![Code Climate](http://img.shields.io/codeclimate/github/dkubb/memoizable.svg)][codeclimate]
[![Coverage Status](http://img.shields.io/coveralls/dkubb/memoizable.svg)][coveralls]

[gem]: https://rubygems.org/gems/memoizable
[travis]: https://travis-ci.org/dkubb/memoizable
[gemnasium]: https://gemnasium.com/dkubb/memoizable
[codeclimate]: https://codeclimate.com/github/dkubb/memoizable
[coveralls]: https://coveralls.io/r/dkubb/memoizable

Memoize method return values

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Rationale

Memoization is an optimization that saves the return value of a method so it
doesn't need to be re-computed every time that method is called. For example,
perhaps you've written a method like this:

```ruby
class Planet
  # This is the equation for the area of a sphere. If it's true for a
  # particular instance of a planet, then that planet is spherical.
  def spherical?
    4 * Math::PI * radius ** 2 == area
  end
end
```

This code will re-compute whether a particular planet is spherical every time
the method is called. If the method is called more than once, it may be more
efficient to save the computed value in an instance variable, like so:

```ruby
class Planet
  def spherical?
    @spherical ||= 4 * Math::PI * radius ** 2 == area
  end
end
```

One problem with this approach is that, if the return value is `false`, the
value will still be computed each time the method is called. It also becomes
unweildy for methods that grow to be longer than one line.

These problems can be solved by mixing-in the `Memoizable` module and memoizing
the method.

```ruby
require 'memoizable'

class Planet
  include Memoizable
  def spherical?
    4 * Math::PI * radius ** 2 == area
  end
  memoize :spherical?
end
```

## Warning

The example above assumes that the radius and area of a planet will not change
over time. This seems like a reasonable assumption but such an assumption is
not safe in every domain. If it was possible for one of the attributes to
change between method calls, memoizing that value could produce the wrong
result. Please keep this in mind when considering which methods to memoize.

Supported Ruby Versions
-----------------------

This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.8.7
* Ruby 1.9.2
* Ruby 1.9.3
* Ruby 2.0.0
* Ruby 2.1.0
* [JRuby][]
* [Rubinius][]
* [Ruby Enterprise Edition][ree]

[jruby]: http://jruby.org/
[rubinius]: http://rubini.us/
[ree]: http://www.rubyenterpriseedition.com/

If something doesn't work on one of these versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby versions or
implementations, however support will only be provided for the implementations
listed above.

If you would like this library to support another Ruby version or
implementation, you may volunteer to be a maintainer. Being a maintainer
entails making sure all tests run and pass on that implementation. When
something breaks on your implementation, you will be responsible for providing
patches in a timely fashion. If critical issues for a particular implementation
exist at the time of a major release, support for that Ruby version may be
dropped.

## Copyright

Copyright &copy; 2013 Dan Kubb, Erik Michaels-Ober. See LICENSE for details.
