# Unaccent

Ruby gem to replace a string's accent characters with unaccented characters. Based on [SixArm Ruby Unaccent](https://github.com/SixArm/sixarm_ruby_unaccent).

[![Gem Version](https://badge.fury.io/rb/unaccent.svg)](https://badge.fury.io/rb/unaccent)
[![Build](https://github.com/hardpixel/unaccent/actions/workflows/build.yml/badge.svg)](https://github.com/hardpixel/unaccent/actions/workflows/build.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/9070ea120ceeddbcc1d2/maintainability)](https://codeclimate.com/github/hardpixel/unaccent/maintainability)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'unaccent'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install unaccent

## Usage

```ruby
require 'unaccent'

Unaccent.unaccent('déjà vu') # deja vu
Unaccent.unaccent('νέα')     # νεα

require 'unaccent/string'

'déjà vu'.unaccent # deja vu
'νέα'.unaccent     # νεα
```

## Benchmark

```
Warming up --------------------------------------
            unaccent     3.259k i/100ms
              sixarm   838.000  i/100ms
Calculating -------------------------------------
            unaccent     32.573k (± 2.1%) i/s -    162.950k in   5.004780s
              sixarm      8.025k (± 4.6%) i/s -     40.224k in   5.023339s

Comparison:
            unaccent:    32573.1 i/s
              sixarm:     8024.7 i/s - 4.06x  (± 0.00) slower

Calculating -------------------------------------
            unaccent     5.947k memsize (     0.000  retained)
                        76.000  objects (     0.000  retained)
                        42.000  strings (     0.000  retained)
              sixarm    29.979k memsize (     0.000  retained)
                       633.000  objects (     0.000  retained)
                        50.000  strings (     0.000  retained)

Comparison:
            unaccent:       5947 allocated
              sixarm:      29979 allocated - 5.04x more
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hardpixel/unaccent.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
