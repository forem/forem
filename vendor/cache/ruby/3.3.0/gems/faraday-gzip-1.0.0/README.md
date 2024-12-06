# Faraday Gzip

![CI](https://github.com/bodrovis/faraday-gzip/actions/workflows/ci.yaml/badge.svg)
[![Gem](https://img.shields.io/gem/v/faraday-gzip.svg?style=flat-square)](https://rubygems.org/gems/faraday-gzip)

The `Gzip` middleware adds the necessary `Accept-Encoding` headers and automatically decompresses the response. If the "Accept-Encoding" header wasn't set in the request, this sets it to "gzip,deflate" and appropriately handles the compressed response from the server. This resembles what Ruby does internally in Net::HTTP#get. If [Brotli](https://github.com/miyucy/brotli) is added to the Gemfile, it will also add "br" to the header.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-gzip'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install faraday-gzip
```

## Usage

```ruby
require 'faraday/gzip'

conn = Faraday.new(...) do |f|
  f.request :gzip
  #...
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `bin/test` to run the tests.

To install this gem onto your local machine, run `rake build`.

To release a new version, make a commit with a message such as "Bumped to 0.0.2" and then run `rake release`.
See how it works [here](https://bundler.io/guides/creating_gem.html#releasing-the-gem).

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
