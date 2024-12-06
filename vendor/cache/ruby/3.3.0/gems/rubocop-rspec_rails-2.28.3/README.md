# RuboCop RSpec Rails

[![Join the chat at https://gitter.im/rubocop-rspec/Lobby](https://badges.gitter.im/rubocop-rspec/Lobby.svg)](https://gitter.im/rubocop-rspec/Lobby)
[![Gem Version](https://badge.fury.io/rb/rubocop-rspec_rails.svg)](https://rubygems.org/gems/rubocop-rspec_rails)
![CI](https://github.com/rubocop/rubocop-rspec_rails/workflows/CI/badge.svg)

[RSpec Rails](https://rspec.info/)-specific analysis for your projects, as an extension to
[RuboCop](https://github.com/rubocop/rubocop).

## Installation

**This gem implicitly depends on the `rubocop-rspec` gem, so you should install it first.**
Just install the `rubocop-rspec` and `rubocop-rspec_rails` gem

```bash
gem install rubocop-rspec rubocop-rspec_rails
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-rspec', require: false
gem 'rubocop-rspec_rails', require: false
```

## Usage

You need to tell RuboCop to load the RSpec Rails extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
require: rubocop-rspec_rails
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
require:
  - rubocop-rspec
  - rubocop-rspec_rails
```

Now you can run `rubocop` and it will automatically load the RuboCop RSpec Rails
cops together with the standard cops.

### Command line

```bash
rubocop --require rubocop-rspec_rails
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rspec_rails'
end
```

## Documentation

You can read more about RuboCop RSpec Rails in its [official manual](https://docs.rubocop.org/rubocop-rspec_rails).

## The Cops

All cops are located under
[`lib/rubocop/cop/rspec_rails`](lib/rubocop/cop/rspec_rails), and contain
examples/documentation.

In your `.rubocop.yml`, you may treat the RSpec Rails cops just like any other
cop. For example:

```yaml
RSpecRails/AvoidSetupHook:
  Exclude:
    - spec/my_poorly_named_spec_file.rb
```

## Contributing

Checkout the [contribution guidelines](.github/CONTRIBUTING.md).

## License

`rubocop-rspec_rails` is MIT licensed. [See the accompanying file](MIT-LICENSE.md) for
the full text.
