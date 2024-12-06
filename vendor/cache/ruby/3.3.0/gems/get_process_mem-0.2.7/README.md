# Get Process Memory

[![Build Status](https://travis-ci.org/schneems/get_process_mem.svg?branch=master)](https://travis-ci.org/schneems/get_process_mem)
[![Help Contribute to Open Source](https://www.codetriage.com/schneems/get_process_mem/badges/users.svg)](https://www.codetriage.com/schneems/get_process_mem)

Do you need to get the memory usage of a process? Great because this library does that.

## Install

In your `Gemfile` add

```ruby
gem 'get_process_mem'
```

then run `$ bundle install`.

If you're using Windows you'll also need to have the `sys-proctable` gem.

## Use It

Get the current process memory usage:

```ruby
mem = GetProcessMem.new
puts mem.inspect
#<GetProcessMem @mb=24.28125 @gb=0.023712158203125 @kb=24864.0 @bytes=25460736 >
mem.bytes # => 25460736
mem.kb    # => 24864.0
mem.mb    # => 24.28125
mem.gb    # => 0.023712158203125
```

Note: All numeric values returned as a float except bytes which is an integer.

Get memory usage of another process:

```ruby
`echo 'nothing to see here' > tmplogf`
pid = Process.spawn('tail -f tmplog')
mem = GetProcessMem.new(pid)
puts mem.inspect
# => #<GetProcessMem @mb=0.48828125 @gb=0.000476837158203125 @kb=500.0 @bytes=512000 >

Process.kill('TERM', pid)
Process.wait(pid)

mem.inspect
# => "#<GetProcessMem @mb=0.0 @gb=0.0 @kb=0.0 @bytes=0>"
`rm tmplog`
```

On Linux, for memory size we return the RSS or the [Resident Set Size](http://en.wikipedia.org/wiki/Resident_set_size), basically how much memory the program takes up in RAM at the time, including all the shared memory.


## License

MIT
