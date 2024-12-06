# Zlib

This module provides access to the [zlib library](http://zlib.net). Zlib is designed to be a portable, free, general-purpose, legally unencumbered -- that is, not covered by any patents -- lossless data-compression library for use on virtually any computer hardware and operating system.

The zlib compression library provides in-memory compression and decompression functions, including integrity checks of the uncompressed data.

The zlib compressed data format is described in RFC 1950, which is a wrapper around a deflate stream which is described in RFC 1951.

The library also supports reading and writing files in gzip (.gz) format with an interface similar to that of IO. The gzip format is described in RFC 1952 which is also a wrapper around a deflate stream.

The zlib format was designed to be compact and fast for use in memory and on communications channels. The gzip format was designed for single-file compression on file systems, has a larger header than zlib to maintain directory information, and uses a different, slower check method than zlib.

See your system's zlib.h for further information about zlib

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zlib'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zlib

## Usage

Using the wrapper to compress strings with default parameters is quite simple:

```ruby
require "zlib"

data_to_compress = File.read("don_quixote.txt")

puts "Input size: #{data_to_compress.size}"
#=> Input size: 2347740

data_compressed = Zlib::Deflate.deflate(data_to_compress)

puts "Compressed size: #{data_compressed.size}"
#=> Compressed size: 887238

uncompressed_data = Zlib::Inflate.inflate(data_compressed)

puts "Uncompressed data is: #{uncompressed_data}"
#=> Uncompressed data is: The Project Gutenberg EBook of Don Quixote...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/zlib.


## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
