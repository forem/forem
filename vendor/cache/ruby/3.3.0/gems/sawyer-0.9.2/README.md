# Sawyer

Sawyer is an experimental hypermedia agent for Ruby built on top of [Faraday][faraday].

[faraday]: https://github.com/lostisland/faraday

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sawyer'
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install sawyer
```

## Usage

```ruby
require "sawyer"

# Create a Sawyer agent
agent = Sawyer::Agent.new("https://api.github.com",
  links_parser: Sawyer::LinkParsers::Simple.new)

# Fetch the root of the API
root = agent.root.data

# Access a resource directly
contributors = agent.call(:get, "repos/lostisland/sawyer/contributors").data

# Load a hypermedia relation
top_contributor = contributors.first
followers = top_contributor.rels[:followers].get.data
```

For more information, check out the [documentation](http://www.rubydoc.info/gems/sawyer/).

## Development

After checking out the repo, run `script/test` to bootstrap the project and run the tests.
You can also run `script/console` for an interactive prompt that will allow you to experiment.

To package the gem, run `script/package`. To release a new version, update the version number in [`lib/sawyer.rb`](lib/sawyer.rb), and then run `script/release`, which will create a git tag for the version, push git commits and tags, and push the .gem file to [rubygems.org](https://rubygems.org).

## Contributing

Check out the [contributing guide](CONTRIBUTING.md) for more information on contributing.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
