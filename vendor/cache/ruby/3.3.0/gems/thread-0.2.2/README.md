# thread

[![Build Status](https://travis-ci.org/meh/ruby-thread.svg?branch=master)](https://travis-ci.org/meh/ruby-thread)

Various extensions to the thread library in ruby.

## Installation

Add this line to your application's Gemfile:

    gem 'thread'

Or install it yourself as:

    $ gem install thread

## Usage

### Pool

All the implementations I looked at were either buggy or wasted CPU resources
for no apparent reason, for example used a sleep of 0.01 seconds to then check for
readiness and stuff like this.

This implementation uses standard locking functions to work properly across multiple Ruby
implementations.

```ruby
require 'thread/pool'

pool = Thread.pool(4)

10.times {
  pool.process {
    sleep 2

    puts 'lol'
  }
}

pool.shutdown
```

You should get 4 lols every 2 seconds and it should exit after 10 of them.

### Channel

This implements a channel where you can write messages and receive messages.

```ruby
require 'thread/channel'

channel = Thread.channel
channel.send 'wat'
channel.receive # => 'wat'

channel = Thread.channel { |o| o.is_a?(Integer) }
channel.send 'wat' # => ArgumentError: guard mismatch

Thread.new {
  while num = channel.receive(&:even?)
    puts 'Aye!'
  end
}

Thread.new {
  while num = channel.receive(&:odd?)
    puts 'Arrr!'
  end
}

loop {
  channel.send rand(1_000_000_000)

  sleep 0.5
}
```

### Pipe

A pipe allows you to execute various tasks on a set of data in parallel,
each datum inserted in the pipe is passed along through queues to the various
functions composing the pipe, the final result is inserted in the final queue.

```ruby
require 'thread/pipe'

p = Thread |-> d { d * 2 } |-> d { d * 4 }
p << 2

puts ~p # => 16
```

### Process

A process helps reducing programming errors coming from race conditions and the
like, the only way to interact with a process is through messages.

Multiple processes should talk with eachother through messages.

```ruby
require 'thread/process'

p = Thread.process {
  loop {
    puts receive.inspect
  }
}

p << 42
p << 23
```

### Promise

This implements the promise pattern, allowing you to pass around an object
where you can send a value and extract a value, in a thread-safe way, accessing
the value will wait for the value to be delivered.

```ruby
require 'thread/promise'

p = Thread.promise

Thread.new {
  sleep 5
  p << 42
}

puts ~p # => 42
```

### Future

A future is somewhat a promise, except you pass it a block to execute in
another thread.

The value returned by the block will be the value of the promise.

By default, `Thread.future` executes the block in a newly-created thread.

`Thread.future` accepts an optional argument of type `Thread.pool` if you want
the block executed in an existing thread-pool.

You can also use the `Thread::Pool` helper `#future`

```ruby
require 'thread/future'

f = Thread.future {
  sleep 5

  42
}

puts ~f # => 42
```

```ruby
require 'thread/pool'
require 'thread/future'

pool = Thread.pool 4
f    = Thread.future pool do
  sleep 5
  42
end

puts ~f # => 42
```

```ruby
require 'thread/pool'
require 'thread/future'

pool = Thread.pool 4
f    = pool.future {
  sleep 5
  42
}

puts ~f # => 42
```


### Delay

A delay is kind of a promise, except the block is called when the value is
being accessed and the result is cached.

```ruby
require 'thread/delay'

d = Thread.delay {
  42
}

puts ~d # => 42
```

### Every

An every executes the block every given seconds and yields the value to the
every object, you can then check if the current value is old or how much time
is left until the second call is done.

```ruby
require 'net/http'
require 'thread/every'

e = Thread.every(5) {
	Net::HTTP.get(URI.parse('http://www.whattimeisit.com/')).match %r{<B>(.*?)<BR>\s+(.*?)</B>}m do |m|
		{ date: m[1], time: m[2] }
	end
}

loop do
	puts ~e
end
```

## Contributing

1. Fork it ( https://github.com/meh/ruby-thread/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Verify new and old specs are green (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
