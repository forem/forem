# Heapy (Ruby Heap Dump Inspector)
[![Help Contribute to Open Source](https://www.codetriage.com/schneems/heapy/badges/users.svg)](https://www.codetriage.com/schneems/heapy) ![Supports Ruby 2.3+](https://img.shields.io/badge/ruby-2.3+-green.svg)

A CLI for analyzing Ruby Heap dumps. Thanks to [Sam Saffron](http://samsaffron.com/archive/2015/03/31/debugging-memory-leaks-in-ruby) for the idea and initial code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'heapy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install heapy

## Usage

### Diff 2 heap dumps

Run with two inputs to output the values of today.dump that are not present in yesterday.dump

```
$ heapy diff tmp/yesterday.dump tmp/today_morning.dump
Allocated STRING 9991 objects of size 399640/491264 (in bytes) at: scratch.rb:24
```

Run with three inputs to show the diff between the first two, but only if the objects are still retained in the third

```
$ heapy diff tmp/yesterday.dump tmp/today_morning.dump tmp/today_afternoon.dump
Retained STRING 9991 objects of size 399640/491264 (in bytes) at: scratch.rb:24
# ...
```

Pass in the name of an output file and the objects present in today.dump that aren't in yesterday.dump will be written to that file

```
$ heapy diff tmp/yesterday.dump tmp/today.dump --output_diff=output.json
Allocated STRING 9991 objects of size 399640/491264 (in bytes) at: scratch.rb:24
# ...
Writing heap dump diff to output.json
```

### Read a Heap Dump

Step 1) Generate a heap dump. You could [do this manually](http://samsaffron.com/archive/2015/03/31/debugging-memory-leaks-in-ruby). Or you can use a tool like [derailed_benchmarks](https://github.com/schneems/derailed_benchmarks)

Step 2) Once you've got the heap dump, you can analyze it using this CLI:

```
$ heapy read tmp/2015-10-01T10:18:59-05:00-heap.dump

Generation: nil object count: 209191
Generation:  14 object count: 407
Generation:  15 object count: 638
Generation:  16 object count: 748
Generation:  17 object count: 1023
Generation:  18 object count: 805
# ...
```

NOTE: The reason you may be getting a "nil" generation is these objects were loaded into memory before your code began tracking the allocations. To ensure all allocations are tracked you can execute your ruby script this trick. First create a file `trace.rb` that only starts allocation tracing:

```
# trace.rb
require 'objspace'

ObjectSpace.trace_object_allocations_start
```

Now make sure this command is loaded before you run your script, you can use Ruby's `-I` to specify a load path and `-r` to specify a library to require, in this case our trace file

```
$ ruby -I ./ -r trace script_name.rb
```

If the last line of your file is invalid JSON, make sure that you are closing the file after writing the ruby heap dump to it.

### Digging into a Generation

You can drill down into a specific generation. In the previous example, the 17'th generation looks strangely large, you can drill into it:

```
$ heapy read tmp/2015-10-01T10:18:59-05:00-heap.dump 17
    Analyzing Heap (Generation: 17)
    -------------------------------

    allocated by memory (44061517) (in bytes)
    ==============================
      39908512  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/timeout.rb:79
       1284993  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/openssl/buffering.rb:182
        201068  /app/vendor/bundle/ruby/2.2.0/gems/json-1.8.3/lib/json/common.rb:223
        189272  /app/vendor/bundle/ruby/2.2.0/gems/newrelic_rpm-3.13.2.302/lib/new_relic/agent/stats_engine/stats_hash.rb:39
        172531  /app/vendor/ruby-2.2.3/lib/ruby/2.2.0/net/http/header.rb:172
         92200  /app/vendor/bundle/ruby/2.2.0/gems/activesupport-4.2.3/lib/active_support/core_ext/numeric/conversions.rb:131
```

You can limit the output by passing in a `--lines` value:

```
$ heapy read tmp/2015-10-01T10:18:59-05:00-heap.dump 17 --lines=6
```

> Note: Default lines value is 50

### Reviewing all generations

If you want to read all generations you can use the "all" directive

```
$ heapy read tmp/2015-10-01T10:18:59-05:00-heap.dump all
```

You can also use T-Lo's online JS based [Heap Analyzer](http://tenderlove.github.io/heap-analyzer/) for visualizations. Another tool is [HARB](https://github.com/csfrancis/harb)

## Development

After checking out the repo, run `$ bundle install` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/schneems/heapy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

