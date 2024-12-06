# Zonebie

[![Build Status](https://secure.travis-ci.org/alindeman/zonebie.png)](http://travis-ci.org/alindeman/zonebie)

Zonebie prevents bugs in code that deals with timezones by randomly assigning a
zone on every run.

If Zonebie helps trigger a timezone-related bug, you can temporarily assign the
`ZONEBIE_TZ` environment variable to make your tests deterministic while you
debug (more information below).

## Requirements

* MRI (2.0.x, 2.1.x, 2.2.x, 2.3.x)
* JRuby (1.7)
* Rubinius (2.0)

***

And **either** of these gems which adds timezone support to Ruby:

* `activesupport` >= 3.0 (Rails 3.0, 3.1, 3.2, 4.0, 4.1, 4.2)
* `tzinfo` >= 1.2

## Installation

If using Bundler (recommended), add to Gemfile:

````ruby
gem 'zonebie'
````

## Usage with Rails & Active Support

Active Support allows setting a global timezone that will be used for many date
and time calculations throughout the application.

Zonebie can set this to a random timezone at the beginning of test runs.
Specifically for Active Support, it sets `Time.zone`.

### Test::Unit & Minitest

Add to `test/test_helper.rb`:

```ruby
Zonebie.set_random_timezone
```

### RSpec

Add to `spec/spec_helper.rb`:

```ruby
require "zonebie/rspec"
```

### Cucumber

Add a file `features/support/zonebie.rb` with the following contents:

```ruby
Zonebie.set_random_timezone
```

## Usage with TZInfo

Zonebie can use the `tzinfo` gem, allowing it to work outside of Active Support
(Rails).

However, `Zonebie.set_random_timezone` does not work outside of Active Support
because there is not a concept of a global timezone setting. If you simply need
a random timezone for some other part of your tests, Zonebie can help.

```ruby
zone = TZInfo::Timezone.get(Zonebie.random_timezone)
puts zone.now

# Also works in Rails/Active Support
zone = ActiveSupport::TimeZone[Zonebie.random_timezone]
puts zone.now
```

## Reproducing Bugs

When `Zonebie.set_random_timezone` is called, Zonebie assigns a timezone and
prints a message to STDOUT:

```
[Zonebie] Setting timezone: ZONEBIE_TZ="Eastern Time (US & Canada)"
```

If you would rather that Zonebie not print out this information during your
tests, put Zonebie in quiet mode before calling `set_random_timezone`:

```ruby
Zonebie.quiet = true
```

To rerun tests with a specific timezone (e.g., to reproduce a bug that only
seems present in one zone), set the `ZONEBIE_TZ` environment variable:

```ruby
# Assuming tests run with simply `rake`
ZONEBIE_TZ="Eastern Time (US & Canada)" rake
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
