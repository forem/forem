# http-parser

Ruby FFI bindings to [http-parser](https://github.com/joyent/http-parser) [![Build Status](https://travis-ci.org/cotag/http-parser.png)](https://travis-ci.org/cotag/http-parser)

## Install

```shell
gem install http-parser
```
This gem will compile a local copy of http-parser


## Usage

```ruby
require 'rubygems'
require 'http-parser'

#
# Create a shared parser
#
parser = HttpParser::Parser.new do |parser|
  parser.on_message_begin do |inst|
    puts "message begin"
  end

  parser.on_message_complete do |inst|
    puts "message end"
  end

  parser.on_url do |inst, data|
    puts "url: #{data}"
  end

  parser.on_header_field do |inst, data|
    puts "field: #{data}"
  end

  parser.on_header_value do |inst, data|
    puts "value: #{data}"
  end
end

#
# Create state objects to track requests through the parser
#
request = HttpParser::Parser.new_instance do |inst|
  inst.type = :request
end

#
# Parse requests
#
parser.parse request, "GET /foo HTTP/1.1\r\n"
sleep 3
parser.parse request, "Host: example.com\r\n"
sleep 3
parser.parse request, "\r\n"

#
# Re-use the memory for another request
#
request.reset!
```

## Acknowledgements

* https://github.com/joyent/http-parser#readme
* https://github.com/postmodern/ffi-http-parser#readme
* https://github.com/deepfryed/http-parser-lite#readme