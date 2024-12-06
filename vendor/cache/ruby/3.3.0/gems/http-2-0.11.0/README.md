# HTTP-2

[![Gem Version](https://badge.fury.io/rb/http-2.svg)](http://rubygems.org/gems/http-2)
[![Build Status](https://travis-ci.org/igrigorik/http-2.svg?branch=master)](https://travis-ci.org/igrigorik/http-2)
[![Coverage Status](https://coveralls.io/repos/igrigorik/http-2/badge.svg)](https://coveralls.io/r/igrigorik/http-2)
[![Analytics](https://ga-beacon.appspot.com/UA-71196-10/http-2/readme)](https://github.com/igrigorik/ga-beacon)

Pure Ruby, framework and transport agnostic, implementation of HTTP/2 protocol and HPACK header compression with support for:

* [Binary framing](https://hpbn.co/http2/#binary-framing-layer) parsing and encoding
* [Stream multiplexing](https://hpbn.co/http2/#streams-messages-and-frames) and [prioritization](https://hpbn.co/http2/#stream-prioritization)
* Connection and stream [flow control](https://hpbn.co/http2/#flow-control)
* [Header compression](https://hpbn.co/http2/#header-compression) and [server push](https://hpbn.co/http2/#server-push)
* Connection and stream management
* And more... see [API docs](http://www.rubydoc.info/github/igrigorik/http-2/frames)

Protocol specifications:

* [Hypertext Transfer Protocol Version 2 (RFC 7540)](https://httpwg.github.io/specs/rfc7540.html)
* [HPACK: Header Compression for HTTP/2 (RFC 7541)](https://httpwg.github.io/specs/rfc7541.html)


## Getting started

```bash
$> gem install http-2
```

This implementation makes no assumptions as how the data is delivered: it could be a regular Ruby TCP socket, your custom eventloop, or whatever other transport you wish to use - e.g. ZeroMQ, [avian carriers](http://www.ietf.org/rfc/rfc1149.txt), etc.

Your code is responsible for feeding data into the parser, which performs all of the necessary HTTP/2 decoding, state management and the rest, and vice versa, the parser will emit bytes (encoded HTTP/2 frames) that you can then route to the destination. Roughly, this works as follows:

```ruby
require 'http/2'
socket = YourTransport.new

conn = HTTP2::Client.new
conn.on(:frame) {|bytes| socket << bytes }

while bytes = socket.read
 conn << bytes
end
```

Checkout provided [client](https://github.com/igrigorik/http-2/blob/master/example/client.rb) and [server](https://github.com/igrigorik/http-2/blob/master/example/server.rb) implementations for basic examples.


### Connection lifecycle management

Depending on the role of the endpoint you must initialize either a [Client](http://www.rubydoc.info/github/igrigorik/http-2/HTTP2/Client) or a [Server](http://www.rubydoc.info/github/igrigorik/http-2/HTTP2/Server) object. Doing so picks the appropriate header compression / decompression algorithms and stream management logic. From there, you can subscribe to connection level events, or invoke appropriate APIs to allocate new streams and manage the lifecycle. For example:

```ruby
# - Server ---------------
server = HTTP2::Server.new

server.on(:stream) { |stream| ... } # process inbound stream
server.on(:frame)  { |bytes| ... }  # encoded HTTP/2 frames

server.ping { ... } # run liveness check, process pong response
server.goaway # send goaway frame to the client

# - Client ---------------
client = HTTP2::Client.new
client.on(:promise) { |stream| ... } # process push promise

stream = client.new_stream # allocate new stream
stream.headers({':method' => 'post', ...}, end_stream: false)
stream.data(payload, end_stream: true)
```

Events emitted by the connection object:

<table>
  <tr>
    <td><b>:promise</b></td>
    <td>client role only, fires once for each new push promise</td>
  </tr>
  <tr>
    <td><b>:stream</b></td>
    <td>server role only, fires once for each new client stream</td>
  </tr>
  <tr>
    <td><b>:frame</b></td>
    <td>fires once for every encoded HTTP/2 frame that needs to be sent to the peer</td>
  </tr>
</table>


### Stream lifecycle management

A single HTTP/2 connection can [multiplex multiple streams](https://hpbn.co/http2/#request-and-response-multiplexing) in parallel: multiple requests and responses can be in flight simultaneously and stream data can be interleaved and prioritized. Further, the specification provides a well-defined lifecycle for each stream (see below).

The good news is, all of the stream management, and state transitions, and error checking is handled by the library. All you have to do is subscribe to appropriate events (marked with ":" prefix in diagram below) and provide your application logic to handle request and response processing.

```
                      +--------+
                 PP   |        |   PP
             ,--------|  idle  |--------.
            /         |        |         \
           v          +--------+          v
    +----------+          |           +----------+
    |          |          | H         |          |
,---|:reserved |          |           |:reserved |---.
|   | (local)  |          v           | (remote) |   |
|   +----------+      +--------+      +----------+   |
|      | :active      |        |      :active |      |
|      |      ,-------|:active |-------.      |      |
|      | H   /   ES   |        |   ES   \   H |      |
|      v    v         +--------+         v    v      |
|   +-----------+          |          +-----------+  |
|   |:half_close|          |          |:half_close|  |
|   |  (remote) |          |          |  (local)  |  |
|   +-----------+          |          +-----------+  |
|        |                 v                |        |
|        |    ES/R    +--------+    ES/R    |        |
|        `----------->|        |<-----------'        |
| R                   | :close |                   R |
`-------------------->|        |<--------------------'
                      +--------+
```

For sake of example, let's take a look at a simple server implementation:

```ruby
conn = HTTP2::Server.new

# emits new streams opened by the client
conn.on(:stream) do |stream|
  stream.on(:active) { } # fires when stream transitions to open state
  stream.on(:close)  { } # stream is closed by client and server

  stream.on(:headers) { |head| ... } # header callback
  stream.on(:data) { |chunk| ... }   # body payload callback

  # fires when client terminates its request (i.e. request finished)
  stream.on(:half_close) do

    # ... generate_response

    # send response
    stream.headers({
      ":status" => 200,
      "content-type" => "text/plain"
    })

    # split response between multiple DATA frames
    stream.data(response_chunk, end_stream: false)
    stream.data(last_chunk)
  end
end
```

Events emitted by the [Stream object](http://www.rubydoc.info/github/igrigorik/http-2/HTTP2/Stream):

<table>
  <tr>
    <td><b>:reserved</b></td>
    <td>fires exactly once when a push stream is initialized</td>
  </tr>
  <tr>
    <td><b>:active</b></td>
    <td>fires exactly once when the stream become active and is counted towards the open stream limit</td>
  </tr>
  <tr>
    <td><b>:headers</b></td>
    <td>fires once for each received header block (multi-frame blocks are reassembled before emitting this event)</td>
  </tr>
  <tr>
    <td><b>:data</b></td>
    <td>fires once for every DATA frame (no buffering)</td>
  </tr>
  <tr>
    <td><b>:half_close</b></td>
    <td>fires exactly once when the opposing peer closes its end of connection (e.g. client indicating that request is finished, or server indicating that response is finished)</td>
  </tr>
  <tr>
    <td><b>:close</b></td>
    <td>fires exactly once when both peers close the stream, or if the stream is reset</td>
  </tr>
  <tr>
    <td><b>:priority</b></td>
    <td>fires once for each received priority update (server only)</td>
  </tr>
</table>


### Prioritization

Each HTTP/2 [stream has a priority value](https://hpbn.co/http2/#stream-prioritization) that can be sent when the new stream is initialized, and optionally reprioritized later:

```ruby
client = HTTP2::Client.new

default_priority_stream = client.new_stream
custom_priority_stream = client.new_stream(priority: 42)

# sometime later: change priority value
custom_priority_stream.reprioritize(32000) # emits PRIORITY frame
```

On the opposite side, the server can optimize its stream processing order or resource allocation by accessing the stream priority value (`stream.priority`).


### Flow control

Multiplexing multiple streams over the same TCP connection introduces contention for shared bandwidth resources. Stream priorities can help determine the relative order of delivery, but priorities alone are insufficient to control how the resource allocation is performed between multiple streams. To address this, HTTP/2 provides a simple mechanism for [stream and connection flow control](https://hpbn.co/http2/#flow-control).

Connection and stream flow control is handled by the library: all streams are initialized with the default window size (64KB), and send/receive window updates are automatically processed - i.e. window is decremented on outgoing data transfers, and incremented on receipt of window frames. Similarly, if the window is exceeded, then data frames are automatically buffered until window is updated.

The only thing left is for your application to specify the logic as to when to emit window updates:

```ruby
conn.buffered_amount     # check amount of buffered data
conn.window              # check current window size
conn.window_update(1024) # increment connection window by 1024 bytes

stream.buffered_amount     # check amount of buffered data
stream.window              # check current window size
stream.window_update(2048) # increment stream window by 2048 bytes
```


### Server push

An HTTP/2 server can [send multiple replies](https://hpbn.co/http2/#server-push) to a single client request. To do so, first it emits a "push promise" frame which contains the headers of the promised resource, followed by the response to the original request, as well as promised resource payloads (which may be interleaved). A simple example is in order:

```ruby
conn = HTTP2::Server.new

conn.on(:stream) do |stream|
  stream.on(:headers) { |head| ... }
  stream.on(:data) { |chunk| ... }

  # fires when client terminates its request (i.e. request finished)
  stream.on(:half_close) do
    promise_header = { ':method' => 'GET',
                       ':authority' => 'localhost',
                       ':scheme' => 'https',
                       ':path' => "/other_resource" }

    # initiate server push stream
    push_stream = nil
    stream.promise(promise_header) do |push|
      push.headers({...})
      push_stream = push
    end

    # send response
    stream.headers({
      ":status" => 200,
      "content-type" => "text/plain"
    })

    # split response between multiple DATA frames
    stream.data(response_chunk, end_stream: false)
    stream.data(last_chunk)
    
    # now send the previously promised data
    push_stream.data(push_data)
  end
end
```

When a new push promise stream is sent by the server, the client is notified via the `:promise` event:

```ruby
conn = HTTP2::Client.new
conn.on(:promise) do |push|
  # process push stream
end
```

The client can cancel any given push stream (via `.close`), or disable server push entirely by sending the appropriate settings frame:

```ruby
client.settings(settings_enable_push: 0)
```
### Specs

To run specs:

```ruby
rake
```

### License

(MIT License) - Copyright (c) 2013 Ilya Grigorik ![GA](https://www.google-analytics.com/__utm.gif?utmac=UA-71196-9&utmhn=github.com&utmdt=HTTP2&utmp=/http-2/readme)
