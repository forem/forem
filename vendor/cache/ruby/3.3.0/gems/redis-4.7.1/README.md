# redis-rb [![Build Status][gh-actions-image]][gh-actions-link] [![Inline docs][inchpages-image]][inchpages-link]

A Ruby client that tries to match [Redis][redis-home]' API one-to-one, while still
providing an idiomatic interface.

See [RubyDoc.info][rubydoc] for the API docs of the latest published gem.

## Getting started

Install with:

```
$ gem install redis
```

You can connect to Redis by instantiating the `Redis` class:

```ruby
require "redis"

redis = Redis.new
```

This assumes Redis was started with a default configuration, and is
listening on `localhost`, port 6379. If you need to connect to a remote
server or a different port, try:

```ruby
redis = Redis.new(host: "10.0.1.1", port: 6380, db: 15)
```

You can also specify connection options as a [`redis://` URL][redis-url]:

```ruby
redis = Redis.new(url: "redis://:p4ssw0rd@10.0.1.1:6380/15")
```

The client expects passwords with special chracters to be URL-encoded (i.e.
`CGI.escape(password)`).

By default, the client will try to read the `REDIS_URL` environment variable
and use that as URL to connect to. The above statement is therefore equivalent
to setting this environment variable and calling `Redis.new` without arguments.

To connect to Redis listening on a Unix socket, try:

```ruby
redis = Redis.new(path: "/tmp/redis.sock")
```

To connect to a password protected Redis instance, use:

```ruby
redis = Redis.new(password: "mysecret")
```

To connect a Redis instance using [ACL](https://redis.io/topics/acl), use:

```ruby
redis = Redis.new(username: 'myname', password: 'mysecret')
```

The Redis class exports methods that are named identical to the commands
they execute. The arguments these methods accept are often identical to
the arguments specified on the [Redis website][redis-commands]. For
instance, the `SET` and `GET` commands can be called like this:

```ruby
redis.set("mykey", "hello world")
# => "OK"

redis.get("mykey")
# => "hello world"
```

All commands, their arguments, and return values are documented and
available on [RubyDoc.info][rubydoc].

## Sentinel support

The client is able to perform automatic failover by using [Redis
Sentinel](http://redis.io/topics/sentinel).  Make sure to run Redis 2.8+
if you want to use this feature.

To connect using Sentinel, use:

```ruby
SENTINELS = [{ host: "127.0.0.1", port: 26380 },
             { host: "127.0.0.1", port: 26381 }]

redis = Redis.new(url: "redis://mymaster", sentinels: SENTINELS, role: :master)
```

* The master name identifies a group of Redis instances composed of a master
and one or more slaves (`mymaster` in the example).

* It is possible to optionally provide a role. The allowed roles are `master`
and `slave`. When the role is `slave`, the client will try to connect to a
random slave of the specified master. If a role is not specified, the client
will connect to the master.

* When using the Sentinel support you need to specify a list of sentinels to
connect to. The list does not need to enumerate all your Sentinel instances,
but a few so that if one is down the client will try the next one. The client
is able to remember the last Sentinel that was able to reply correctly and will
use it for the next requests.

If you want to [authenticate](https://redis.io/topics/sentinel#configuring-sentinel-instances-with-authentication) Sentinel itself, you must specify the `password` option per instance.

```ruby
SENTINELS = [{ host: '127.0.0.1', port: 26380, password: 'mysecret' },
             { host: '127.0.0.1', port: 26381, password: 'mysecret' }]

redis = Redis.new(host: 'mymaster', sentinels: SENTINELS, role: :master)
```

## Cluster support

`redis-rb` supports [clustering](https://redis.io/topics/cluster-spec).

```ruby
# Nodes can be passed to the client as an array of connection URLs.
nodes = (7000..7005).map { |port| "redis://127.0.0.1:#{port}" }
redis = Redis.new(cluster: nodes)

# You can also specify the options as a Hash. The options are the same as for a single server connection.
(7000..7005).map { |port| { host: '127.0.0.1', port: port } }
```

You can also specify only a subset of the nodes, and the client will discover the missing ones using the [CLUSTER NODES](https://redis.io/commands/cluster-nodes) command.

```ruby
Redis.new(cluster: %w[redis://127.0.0.1:7000])
```

If you want [the connection to be able to read from any replica](https://redis.io/commands/readonly), you must pass the `replica: true`. Note that this connection won't be usable to write keys.

```ruby
Redis.new(cluster: nodes, replica: true)
```

The calling code is responsible for [avoiding cross slot commands](https://redis.io/topics/cluster-spec#keys-distribution-model).

```ruby
redis = Redis.new(cluster: %w[redis://127.0.0.1:7000])

redis.mget('key1', 'key2')
#=> Redis::CommandError (CROSSSLOT Keys in request don't hash to the same slot)

redis.mget('{key}1', '{key}2')
#=> [nil, nil]
```

* The client automatically reconnects after a failover occurred, but the caller is responsible for handling errors while it is happening.
* The client support permanent node failures, and will reroute requests to promoted slaves.
* The client supports `MOVED` and `ASK` redirections transparently.

## Cluster mode with SSL/TLS
Since Redis can return FQDN of nodes in reply to client since `7.*` with CLUSTER commands, we can use cluster feature with SSL/TLS connection like this:

```ruby
Redis.new(cluster: %w[rediss://foo.example.com:6379])
```

On the other hand, in Redis versions prior to `6.*`, you can specify options like the following if cluster mode is enabled and client has to connect to nodes via single endpoint with SSL/TLS.

```ruby
Redis.new(cluster: %w[rediss://foo-endpoint.example.com:6379], fixed_hostname: 'foo-endpoint.example.com')
```

In case of the above architecture, if you don't pass the `fixed_hostname` option to the client and servers return IP addresses of nodes, the client may fail to verify certificates.

## Storing objects

Redis "string" types can be used to store serialized Ruby objects, for
example with JSON:

```ruby
require "json"

redis.set "foo", [1, 2, 3].to_json
# => OK

JSON.parse(redis.get("foo"))
# => [1, 2, 3]
```

## Pipelining

When multiple commands are executed sequentially, but are not dependent,
the calls can be *pipelined*. This means that the client doesn't wait
for reply of the first command before sending the next command. The
advantage is that multiple commands are sent at once, resulting in
faster overall execution.

The client can be instructed to pipeline commands by using the
`#pipelined` method. After the block is executed, the client sends all
commands to Redis and gathers their replies. These replies are returned
by the `#pipelined` method.

```ruby
redis.pipelined do |pipeline|
  pipeline.set "foo", "bar"
  pipeline.incr "baz"
end
# => ["OK", 1]
```

### Executing commands atomically

You can use `MULTI/EXEC` to run a number of commands in an atomic
fashion. This is similar to executing a pipeline, but the commands are
preceded by a call to `MULTI`, and followed by a call to `EXEC`. Like
the regular pipeline, the replies to the commands are returned by the
`#multi` method.

```ruby
redis.multi do |transaction|
  transaction.set "foo", "bar"
  transaction.incr "baz"
end
# => ["OK", 1]
```

### Futures

Replies to commands in a pipeline can be accessed via the *futures* they
emit (since redis-rb 3.0). All calls on the pipeline object return a
`Future` object, which responds to the `#value` method. When the
pipeline has successfully executed, all futures are assigned their
respective replies and can be used.

```ruby
redis.pipelined do |pipeline|
  @set = pipeline.set "foo", "bar"
  @incr = pipeline.incr "baz"
end

@set.value
# => "OK"

@incr.value
# => 1
```

## Error Handling

In general, if something goes wrong you'll get an exception. For example, if
it can't connect to the server a `Redis::CannotConnectError` error will be raised.

```ruby
begin
  redis.ping
rescue StandardError => e
  e.inspect
# => #<Redis::CannotConnectError: Timed out connecting to Redis on 10.0.1.1:6380>

  e.message
# => Timed out connecting to Redis on 10.0.1.1:6380
end
```

See lib/redis/errors.rb for information about what exceptions are possible.

## Timeouts

The client allows you to configure connect, read, and write timeouts.
Passing a single `timeout` option will set all three values:

```ruby
Redis.new(:timeout => 1)
```

But you can use specific values for each of them:

```ruby
Redis.new(
  :connect_timeout => 0.2,
  :read_timeout    => 1.0,
  :write_timeout   => 0.5
)
```

All timeout values are specified in seconds.

When using pub/sub, you can subscribe to a channel using a timeout as well:

```ruby
redis = Redis.new(reconnect_attempts: 0)
redis.subscribe_with_timeout(5, "news") do |on|
  on.message do |channel, message|
    # ...
  end
end
```

If no message is received after 5 seconds, the client will unsubscribe.

## Reconnections

The client allows you to configure how many `reconnect_attempts` it should
complete before declaring a connection as failed. Furthermore, you may want
to control the maximum duration between reconnection attempts with
`reconnect_delay` and `reconnect_delay_max`.

```ruby
Redis.new(
  :reconnect_attempts => 10,
  :reconnect_delay => 1.5,
  :reconnect_delay_max => 10.0,
)
```

The delay values are specified in seconds. With the above configuration, the
client would attempt 10 reconnections, exponentially increasing the duration
between each attempt but it never waits longer than `reconnect_delay_max`.

This is the retry algorithm:

```ruby
attempt_wait_time = [(reconnect_delay * 2**(attempt-1)), reconnect_delay_max].min
```

**By default**, this gem will only **retry a connection once** and then fail, but with the
above configuration the reconnection attempt would look like this:

#|Attempt wait time|Total wait time
:-:|:-:|:-:
1|1.5s|1.5s
2|3.0s|4.5s
3|6.0s|10.5s
4|10.0s|20.5s
5|10.0s|30.5s
6|10.0s|40.5s
7|10.0s|50.5s
8|10.0s|60.5s
9|10.0s|70.5s
10|10.0s|80.5s

So if the reconnection attempt #10 succeeds 70 seconds have elapsed trying
to reconnect, this is likely fine in long-running background processes, but if
you use Redis to drive your website you might want to have a lower
`reconnect_delay_max` or have less `reconnect_attempts`.

## SSL/TLS Support

This library supports natively terminating client side SSL/TLS connections
when talking to Redis via a server-side proxy such as [stunnel], [hitch],
or [ghostunnel].

To enable SSL support, pass the `:ssl => true` option when configuring the
Redis client, or pass in `:url => "rediss://..."` (like HTTPS for Redis).
You will also need to pass in an `:ssl_params => { ... }` hash used to
configure the `OpenSSL::SSL::SSLContext` object used for the connection:

```ruby
redis = Redis.new(
  :url        => "rediss://:p4ssw0rd@10.0.1.1:6381/15",
  :ssl_params => {
    :ca_file => "/path/to/ca.crt"
  }
)
```

The options given to `:ssl_params` are passed directly to the
`OpenSSL::SSL::SSLContext#set_params` method and can be any valid attribute
of the SSL context. Please see the [OpenSSL::SSL::SSLContext documentation]
for all of the available attributes.

Here is an example of passing in params that can be used for SSL client
certificate authentication (a.k.a. mutual TLS):

```ruby
redis = Redis.new(
  :url        => "rediss://:p4ssw0rd@10.0.1.1:6381/15",
  :ssl_params => {
    :ca_file => "/path/to/ca.crt",
    :cert    => OpenSSL::X509::Certificate.new(File.read("client.crt")),
    :key     => OpenSSL::PKey::RSA.new(File.read("client.key"))
  }
)
```

[stunnel]: https://www.stunnel.org/
[hitch]: https://hitch-tls.org/
[ghostunnel]: https://github.com/square/ghostunnel
[OpenSSL::SSL::SSLContext documentation]: http://ruby-doc.org/stdlib-2.3.0/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html

*NOTE:* SSL is only supported by the default "Ruby" driver


## Expert-Mode Options

 - `inherit_socket: true`: disable safety check that prevents a forked child
   from sharing a socket with its parent; this is potentially useful in order to mitigate connection churn when:
    - many short-lived forked children of one process need to talk
      to redis, AND
    - your own code prevents the parent process from using the redis
      connection while a child is alive

   Improper use of `inherit_socket` will result in corrupted and/or incorrect
   responses.

## Alternate drivers

By default, redis-rb uses Ruby's socket library to talk with Redis.
To use an alternative connection driver it should be specified as option
when instantiating the client object. These instructions are only valid
for **redis-rb 3.0**. For instructions on how to use alternate drivers from
**redis-rb 2.2**, please refer to an [older README][readme-2.2.2].

[readme-2.2.2]: https://github.com/redis/redis-rb/blob/v2.2.2/README.md

### hiredis

The hiredis driver uses the connection facility of hiredis-rb. In turn,
hiredis-rb is a binding to the official hiredis client library. It
optimizes for speed, at the cost of portability. Because it is a C
extension, JRuby is not supported (by default).

It is best to use hiredis when you have large replies (for example:
`LRANGE`, `SMEMBERS`, `ZRANGE`, etc.) and/or use big pipelines.

In your Gemfile, include hiredis:

```ruby
gem "redis", "~> 3.0.1"
gem "hiredis", "~> 0.4.5"
```

When instantiating the client object, specify hiredis:

```ruby
redis = Redis.new(:driver => :hiredis)
```

### synchrony

The synchrony driver adds support for [em-synchrony][em-synchrony].
This makes redis-rb work with EventMachine's asynchronous I/O, while not
changing the exposed API. The hiredis gem needs to be available as
well, because the synchrony driver uses hiredis for parsing the Redis
protocol.

[em-synchrony]: https://github.com/igrigorik/em-synchrony

In your Gemfile, include em-synchrony and hiredis:

```ruby
gem "redis", "~> 3.0.1"
gem "hiredis", "~> 0.4.5"
gem "em-synchrony"
```

When instantiating the client object, specify synchrony:

```ruby
redis = Redis.new(:driver => :synchrony)
```

## Testing

This library is tested against recent Ruby and Redis versions.
Check [Github Actions][gh-actions-link] for the exact versions supported.

## See Also

- [async-redis](https://github.com/socketry/async-redis) — An [async](https://github.com/socketry/async) compatible Redis client.

## Contributors

Several people contributed to redis-rb, but we would like to especially
mention Ezra Zygmuntowicz. Ezra introduced the Ruby community to many
new cool technologies, like Redis. He wrote the first version of this
client and evangelized Redis in Rubyland. Thank you, Ezra.

## Contributing

[Fork the project](https://github.com/redis/redis-rb) and send pull
requests.


[inchpages-image]:  https://inch-ci.org/github/redis/redis-rb.svg
[inchpages-link]:   https://inch-ci.org/github/redis/redis-rb
[redis-commands]:   https://redis.io/commands
[redis-home]:       https://redis.io
[redis-url]:        http://www.iana.org/assignments/uri-schemes/prov/redis
[gh-actions-image]: https://github.com/redis/redis-rb/workflows/Test/badge.svg
[gh-actions-link]:  https://github.com/redis/redis-rb/actions
[rubydoc]:          http://www.rubydoc.info/gems/redis
