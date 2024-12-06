## 4.1

Rice 4.1 builds on the 4.0 release and has a number of improvements that both polish Rice and extend its functionality. However, there are three incompatibilities to know about:

* Exception handlers are now registered globally versus per module. This requires updating code that calls Class#add_handler to use register_handler instead.
* Rename Arg#isValue to Arg#setValue and then Arg#getIsValue to Arg#isValue
* Rename Return#isValue to Return#setValue and Return#getIsValue to Return#isValue 

New or improved functionality includes:

* Add support for std::map, std::unordered_map, std::variant, std::monostate and std::reference_wrapper
* Enable calling of C++ member functions that are defined in ancestor classes
* Make it easy to wrap C++ iterators like std::vector begin and end
* Enable creating enumerators for C++ collections like std::vector and std::map
* Enable calling more Ruby API methods including those with a variable number of parameters such as rb_yield_values
* Add additional C++ to Ruby exception mappings (for example, std::system_error to SystemCallError)
* Updated documentation, including new pages for instance tracking, iterators, exceptions and newly supported STL classes
* Add support for calling Ruby methods with keywords from Rice::Object and its descendants
* Automatically translate C++ character arrays that start with colons to symbols (ie, ":mysymbol") when sending them to Ruby
* Add a constructor for Rice::Module that takes a name, to enable code like Module("Kernel")
* Fix comparison methods in Rice::Object, such as Object#is_equal, to return the correct result
* Fix various compiler warnings
* Remove deprecated APIs
* Remove support for Ruby 2.5 and 2.6 which are officially out of support
* Add support for building tests with CMake
* And lots of other fixes and code improvements

Rice also includes experimental support for instance tracking so that Rice maps the same C++ instance to the same Ruby instance each time it is passed to Ruby. See the documentation for more information.


## 4.0

Rice 4.0 is a significant change from 3.0 and has multiple backwards-incompatible
changes. Rice 4.0 no longer requires pre-compilation and is now a header-only library,
delivered as a combined header file.

For migrating from 3 to 4, see [the migration guide](https://jasonroelofs.com/rice/4.x/migration.html).

There are a ton of changes, but some of the most important ones:

* Header only! `#include <rice/rice.hpp>`
* Requires C++17 or later
* Brand new, expanded documentation
* [Built-in STL support](https://jasonroelofs.com/rice/4.x/stl/stl.html)
* And so much more. See the documentation for more details.

## 3.0

* Now requires a compiler supporting for C++14 or later
* Drop support for Ruby 2.4. Supported versions are now 2.5 through 3.0.
* Fix build issue on macOS Big Sur
* Fix a data corruption issue with `Rice::Exception::what`.
* Move CI from Travis to GitHub Actions. Now also able to verify Windows builds!

## 2.2.0

* Deprecate support for Rubies older than 2.4
* Provide a few more built-in to_ruby/from_ruby conversions
* Fix compilation error when building under Ruby 2.7.0

## 2.1.3

* Don't lock down HAVE_CXX11 on the Rice build itself.

## 2.1.2

* Fix defining custom `begin` and `end` methods on an `Iterator`

## 2.1.1

* Support Ruby 2.4
* Re-enable Rice::Enum#hash to support putting Enums in Hashes

## 2.1.0

* Fix compliation issues related to g++ and Ruby 2.3.0
  To do this, I had to remove Array::to_c_array which was exposing the internals of a
	Ruby RArray type to the system. This is not something that we should support going forward
	as these internals are going to change.

# 2.0.0

* Deprecated all versions of Ruby < 2.0
* Removed Rice::VM.
  Unsure if this class is even used anywhere and it felt strange to be
  able to load up a Ruby interpreter inside of Ruby. If you need it, it's
  two files that I can easily make available in a gist.
* Improve build process across architectures and future changes.
  Included some extra warnings for XCode updates on Mac OS X.
* Confirmed that Rice definitely does not work on static Ruby builds,
  but that seems to be more because newer Ruby versions don't have good static builds.
  Thanks to @Kagetsuki for his help tracking down what's going on here.

## 1.7.0

* Ruby 2.2 support
  Potential breaking changes. Ruby 2.2 removed RHash as a public accessible struct
  and as such I changed all of the Builtin_Objects to work directly off of RObject
  instead of the specifics (RArray, RStruct, RString, etc). If you've been using these
  objects directly I recommend using either the Rice API or Ruby's CAPI instead for
  future compatibility.

## 1.6.3

* Fix complication issue on some 64-bit *nix systems

## 1.6.2

* Oops! Missed new file in the gemspec

## 1.6.1

* Support C++x11 uniqe_ptr over auto_ptr
* Fix some warnings

## 1.6.0

* Ruby 2.1 support -- Thanks Chai Zhenhua
* Methods and Constructors have correct method access specifiers [#57]
* Clean up some 64-bit compiler warnings

## 1.5.3

* Fix signed / unsigned compiler warning with Hash#each
* Fix compilation on clang 5 (Xcode 5)

## 1.5.2

* Update build system to remove deprecation warnings and allow easier building
* Fix String to work as a parameter in a wrapped method (#59)
* Update documentation a bit

## 1.5.1

* Doc string fix

## 1.5.0

* Ruby 2.0 compatability
* Bug fixes

## 1.4.3

* Various build configuration fixes

## 1.4.0

* Fully compatible with Ruby 1.9.2
* Constructor supports default arguments
* Ability to define implicit casting through define_implicit_cast
* Fixed a few memory-related issues
