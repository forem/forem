# Faraday::Encoding

[![Gem Version](https://badge.fury.io/rb/faraday-encoding.svg)](http://badge.fury.io/rb/faraday-encoding)
[![Build Status](https://travis-ci.org/ma2gedev/faraday-encoding.svg)](https://travis-ci.org/ma2gedev/faraday-encoding)

A Faraday Middleware sets body encoding when specified by server.

## Motivation

Response body's encoding is set always ASCII-8BIT using with net/http adapter.
Net::HTTP doesn't handle encoding when server specifies encoding in content-type header.
Sometimes we caught an Error such as the following:

```ruby
body = Faraday.new(url: 'https://example.com').get('/').body
# body contains utf-8 string. ex: "赤坂"
body.to_json
# => raise Encoding::UndefinedConversionError: "\xE8" from ASCII-8BIT to UTF-8
```

That's why I wrote Farday::Encoding gem.

SEE ALSO: [response.body is ASCII-8BIT when Content-Type is text/xml; charset=utf-8](https://github.com/lostisland/faraday/issues/139)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday-encoding'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faraday-encoding

## Usage

```ruby
require 'faraday/encoding'

conn = Faraday.new do |connection|
  connection.response :encoding  # use Faraday::Encoding middleware
  connection.adapter Faraday.default_adapter # net/http
end

response = conn.get '/nya.html'  # content-type is specified as 'text/plain; charset=utf-8'
response.body.encoding
# => #<Encoding:UTF-8>
```

## Contributing

1. Fork it ( https://github.com/ma2gedev/faraday-encoding/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
