# HEAD

# 1.3.2

* Compatibility with Oga 0.3

# 1.3.1

* Allow default value to be `false` [[#66](https://github.com/pauldix/sax-machine/pull/66)]
* Support adding class to an attribute [[#68](https://github.com/pauldix/sax-machine/pull/68)]
* Adjust Ox handler to skip empty text/cdata values

# 1.3.0

* Improve block modifiers to support all config options
* Make block modifiers run in instance context
* Make all handlers support IO as a input

# 1.2.0

* Add support for blocks as value modifiers [[#61](https://github.com/pauldix/sax-machine/pull/61)]

# 1.1.1

* Fix Nokogiri autoloading [[#60](https://github.com/pauldix/sax-machine/pull/60)]

# 1.1.0

* Option to use Oga as a SAX handler

# 1.0.3

* Remove missed `nokogiri` reference [[#54](https://github.com/pauldix/sax-machine/pull/54)]
* Add support for `Symbol` data type conversion [[#57](https://github.com/pauldix/sax-machine/pull/57)]
* Add specs for multiple elements with the same alias [[#53](https://github.com/pauldix/sax-machine/pull/53)]
* Various code and documentation enhancements

# 1.0.2

* Make sure SAXConfig getters do not modify internal vars. Prevent race conditions

# 1.0.1

* Improve normalize_name performance

# 1.0.0

* Make `nokogiri` dependency optional
* Add :default argument for elements [[#51](https://github.com/pauldix/sax-machine/pull/51)]

# 0.3.0

* Option to use Ox as a SAX handler instead of Nokogiri [[#49](https://github.com/pauldix/sax-machine/pull/49)]
* Bump RSpec to 3.0, convert existing specs

# 0.2.1

* Turn on replace_entities on Nokogiri parser [[#40](https://github.com/pauldix/sax-machine/pull/40)]
* Provide mass assignment through initialize method [[#38](https://github.com/pauldix/sax-machine/pull/38)]
* Bump nokogiri (~> 1.6) and rspec, drop growl dependency
* Update 'with' option to allow pattern matching in addition to string matching

# 0.2.0.rc1

* Try to reduce the number of instances of respond_to? in the code by
  pulling common uses of it out to methods. [[#32](https://github.com/pauldix/sax-machine/pull/32)]
* The parse stack is now composed of simple objects instead of it being
  an array of arrays. [[#32](https://github.com/pauldix/sax-machine/pull/32)]
* Now using an identifier for an empty buffer instead of empty string. [[#32](https://github.com/pauldix/sax-machine/pull/32)]
* Clean up several variables that were not being used. [[#32](https://github.com/pauldix/sax-machine/pull/32)]
* Encapsulate stack so it's not being exposed as part of the API. [[#32](https://github.com/pauldix/sax-machine/pull/32)]
* `cdata_block` is now an alias instead of delegating to characters. [[#32](https://github.com/pauldix/sax-machine/pull/32)]

# 0.1.0

* Rename parent to ancestor
* Add SAXMachine.configure
