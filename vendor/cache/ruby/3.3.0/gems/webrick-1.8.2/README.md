# Webrick

WEBrick is an HTTP server toolkit that can be configured as an HTTPS server, a proxy server, and a virtual-host server.

WEBrick features complete logging of both server operations and HTTP access.

WEBrick supports both basic and digest authentication in addition to algorithms not in RFC 2617.

A WEBrick server can be composed of multiple WEBrick servers or servlets to provide differing behavior on a per-host or per-path basis. WEBrick includes servlets for handling CGI scripts, ERB pages, Ruby blocks and directory listings.

WEBrick also includes tools for daemonizing a process and starting a process at a higher privilege level and dropping permissions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'webrick'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install webrick

## Usage

To create a new WEBrick::HTTPServer that will listen to connections on port 8000 and serve documents from the current user's public_html folder:

```ruby
require 'webrick'

root = File.expand_path '~/public_html'
server = WEBrick::HTTPServer.new :Port => 8000, :DocumentRoot => root
```

To run the server you will need to provide a suitable shutdown hook as
starting the server blocks the current thread:

```ruby
trap 'INT' do server.shutdown end

server.start
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/webrick.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
