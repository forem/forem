# RuboCop Capybara

[![Join the chat at https://gitter.im/rubocop-rspec/Lobby](https://badges.gitter.im/rubocop-rspec/Lobby.svg)](https://gitter.im/rubocop-rspec/Lobby)
[![Gem Version](https://badge.fury.io/rb/rubocop-capybara.svg)](https://rubygems.org/gems/rubocop-capybara)
![CI](https://github.com/rubocop/rubocop-capybara/workflows/CI/badge.svg)

[Capybara](https://teamcapybara.github.io/capybara)-specific analysis for your projects, as an extension to
[RuboCop](https://github.com/rubocop/rubocop).

## Installation

Just install the `rubocop-capybara` gem

```bash
gem install rubocop-capybara
```

or if you use bundler put this in your `Gemfile`

```ruby
gem 'rubocop-capybara', require: false
```

## Usage

You need to tell RuboCop to load the Capybara extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
require: rubocop-capybara
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
require:
  - rubocop-other-extension
  - rubocop-capybara
```

Now you can run `rubocop` and it will automatically load the RuboCop Capybara
cops together with the standard cops.

### Command line

```bash
rubocop --require rubocop-capybara
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-capybara'
end
```

## Documentation

You can read more about RuboCop Capybara in its [official manual](https://docs.rubocop.org/rubocop-capybara).

## The Cops

All cops are located under
[`lib/rubocop/cop/capybara`](lib/rubocop/cop/capybara), and contain
examples/documentation.

In your `.rubocop.yml`, you may treat the Capybara cops just like any other
cop. For example:

```yaml
Capybara/SpecificMatcher:
  Exclude:
    - spec/my_spec.rb
```

## Contributing

Checkout the [contribution guidelines](.github/CONTRIBUTING.md).

## License

`rubocop-capybara` is MIT licensed. [See the accompanying file](MIT-LICENSE.md) for
the full text.
