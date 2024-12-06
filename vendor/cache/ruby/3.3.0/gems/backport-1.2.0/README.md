# Backport

A pure Ruby library for event-driven IO.

This library is designed with portability as the highest priority, which is why it's written in pure Ruby. Consider [EventMachine](https://github.com/eventmachine/eventmachine) if you need a solution that's faster, more mature, and scalable.

## Installation

Install the gem:

```
gem install backport
```

Or add it to your application's Gemfile:

```ruby
gem 'backport'
```

## Usage

### Examples

A simple echo server:

```ruby
require 'backport'

module MyAdapter
  def opening
    puts "Opening a connection"
  end

  def closing
    puts "Closing a connection"
  end

  def receiving data
    write "Client sent: #{data}"
  end
end

Backport.run do
  Backport.prepare_tcp_server(host: 'localhost', port: 8000, adapter: MyAdapter)
end
```

An interval server that runs once per second:

```ruby
require 'backport'

Backport.run do
  Backport.prepare_interval 1 do
    puts "tick"
  end
end
```

### Using Adapters

Backport servers that handle client connections, such as TCP servers, use an
adapter to provide an application interface to the client. Developers can
provide their own adapter implementations in two ways: a Ruby module that will
be used to extend a Backport::Adapter object, or a class that extends
Backport::Adapter. In either case, the adapter should provide the following
methods:

* `opening`: A callback triggered when the client connection is accepted
* `closing`: A callback triggered when the client connection is closed
* `receiving(data)`: A callback triggered when the server receives data from the client

Backport::Adapter also provides the following methods:

* `write(data)`: Send raw data to the client
* `write_line(data)`: Send a line of data to the client
* `close`: Disconnect the client from the server
* `closed?`: True if the connection is closed
* `remote`: A hash of data about the client, e.g., the remote IP address
