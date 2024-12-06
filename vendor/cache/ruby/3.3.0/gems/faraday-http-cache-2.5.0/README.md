# Faraday Http Cache

[![Gem Version](https://badge.fury.io/rb/faraday-http-cache.svg)](https://rubygems.org/gems/faraday-http-cache)
[![Build](https://github.com/sourcelevel/faraday-http-cache/actions/workflows/main.yml/badge.svg)](https://github.com/sourcelevel/faraday-http-cache/actions)

A [Faraday](https://github.com/lostisland/faraday) middleware that respects HTTP cache,
by checking expiration and validation of the stored responses.

## Installation

Add it to your Gemfile:

```ruby
gem 'faraday-http-cache'
```

## Usage and configuration

You have to use the middleware in the Faraday instance that you want to,
along with a suitable `store` to cache the responses. You can use the new
shortcut using a symbol or passing the middleware class

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache
  # or
  builder.use Faraday::HttpCache, store: Rails.cache

  builder.adapter Faraday.default_adapter
end
```

The middleware accepts a `store` option for the cache backend responsible for recording
the API responses that should be stored. Stores should respond to `write`, `read` and `delete`,
just like an object from the `ActiveSupport::Cache` API.

```ruby
# Connect the middleware to a Memcache instance.
store = ActiveSupport::Cache.lookup_store(:mem_cache_store, ['localhost:11211'])

client = Faraday.new do |builder|
  builder.use :http_cache, store: store
  builder.adapter Faraday.default_adapter
end

# Or use the Rails.cache instance inside your Rails app.
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache
  builder.adapter Faraday.default_adapter
end
```
The default store provided is a simple in memory cache that lives on the client instance.
This type of store **might not be persisted across multiple processes or connection instances**
so it is probably not suitable for most production environments.
Make sure that you configure a store that is suitable for you.

The stdlib `JSON` module is used for serialization by default, which can struggle with unicode
characters in responses in Ruby < 3.1. For example, if your JSON returns `"name": "Raül"` then
you might see errors like:

```
Response could not be serialized: "\xC3" from ASCII-8BIT to UTF-8. Try using Marshal to serialize.
```

For full unicode support, or if you expect to be dealing with images, you can use the stdlib
[Marshal][marshal] instead. Alternatively you could use another json library like `oj` or `yajl-ruby`.

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache, serializer: Marshal
  builder.adapter Faraday.default_adapter
end
```

### Strategies

You can provide a `:strategy` option to the middleware to specify the strategy to use.

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache, strategy: Faraday::HttpCache::Strategies::ByVary
  builder.adapter Faraday.default_adapter
end
```

Available strategies are:

#### `Faraday::HttpCache::Strategies::ByUrl`

The default strategy.
It Uses URL + HTTP method to generate cache keys and stores an array of request + response for each key.

#### `Faraday::HttpCache::Strategies::ByVary`

This strategy uses headers from `Vary` header to generate cache keys.
It also uses cache to store `Vary` headers mapped to the request URL.
This strategy is more suitable for caching private responses with the same URLs but different results for different users, like `https://api.github.com/user`.

*Note:* To automatically remove stale cache keys, you might want to use the `:expires_in` option.

```ruby
store = ActiveSupport::Cache.lookup_store(:redis_cache_store, expires_in: 1.day, url: 'redis://localhost:6379/0')
client = Faraday.new do |builder|
  builder.use :http_cache, store: store, strategy: Faraday::HttpCache::Strategies::ByVary
  builder.adapter Faraday.default_adapter
end
```

#### Custom strategies

You can write your own strategy by subclassing `Faraday::HttpCache::Strategies::BaseStrategy` and implementing `#write`, `#read` and `#delete` methods.

### Logging

You can provide a `:logger` option that will receive debug information based on the middleware
operations:

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache, logger: Rails.logger
  builder.adapter Faraday.default_adapter
end

client.get('https://site/api/users')
# logs "HTTP Cache: [GET users] miss, store"
```

### Instrumentation

In addition to logging you can instrument the middleware by passing in an `:instrumenter` option
such as ActiveSupport::Notifications (compatible objects are also allowed).

The event `http_cache.faraday` will be published every time the middleware
processes a request. In the event payload, `:env` contains the response Faraday env and
`:cache_status` contains a Symbol indicating the status of the cache processing for that request:

- `:unacceptable` means that the request did not go through the cache at all.
- `:miss` means that no cached response could be found.
- `:invalid` means that the cached response could not be validated against the server.
- `:valid` means that the cached response *could* be validated against the server.
- `:fresh` means that the cached response was still fresh and could be returned without even
  calling the server.

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, store: Rails.cache, instrumenter: ActiveSupport::Notifications
  builder.adapter Faraday.default_adapter
end

# Subscribes to all events from Faraday::HttpCache.
ActiveSupport::Notifications.subscribe "http_cache.faraday" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  cache_status = event.payload[:cache_status]
  statsd = Statsd.new

  case cache_status
  when :fresh, :valid
    statsd.increment('api-calls.cache_hits')
  when :invalid, :miss
    statsd.increment('api-calls.cache_misses')
  when :unacceptable
    statsd.increment('api-calls.cache_bypass')
  end
end
```

## See it live

You can clone this repository, install its dependencies with Bundler (run `bundle install`) and
execute the files under the `examples` directory to see a sample of the middleware usage.

## What gets cached?

The middleware will use the following headers to make caching decisions:
- Vary
- Cache-Control
- Age
- Last-Modified
- ETag
- Expires

### Cache-Control

The `max-age`, `must-revalidate`, `proxy-revalidate` and `s-maxage` directives are checked.

### Shared vs. non-shared caches

By default, the middleware acts as a "shared cache" per RFC 2616. This means it does not cache
responses with `Cache-Control: private`. This behavior can be changed by passing in the
`:shared_cache` configuration option:

```ruby
client = Faraday.new do |builder|
  builder.use :http_cache, shared_cache: false
  builder.adapter Faraday.default_adapter
end

client.get('https://site/api/some-private-resource') # => will be cached
```

## License

Copyright (c) 2012-2018 Plataformatec.
Copyright (c) 2019 SourceLevel and contributors.

  [marshal]: https://www.ruby-doc.org/core-3.0/Marshal.html
