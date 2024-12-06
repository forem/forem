# dogstatsd-ruby

A client for DogStatsD, an extension of the StatsD metric server for Datadog. Full API documentation is available in [DogStatsD-ruby rubydoc](https://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog/Statsd).

[![Build Status](https://secure.travis-ci.org/DataDog/dogstatsd-ruby.svg)](http://travis-ci.org/DataDog/dogstatsd-ruby)

See [CHANGELOG.md](CHANGELOG.md) for changes. To suggest a feature, report a bug, or general discussion, [open an issue](http://github.com/DataDog/dogstatsd-ruby/issues/).

## Installation

First install the library:

```
gem install dogstatsd-ruby
```

## Configuration

To instantiate a DogStatsd client:

```ruby
# Import the library
require 'datadog/statsd'

# Create a DogStatsD client instance
statsd = Datadog::Statsd.new('localhost', 8125)
# ...
# release resources used by the client instance
statsd.close()
```
Or if you want to connect over Unix Domain Socket:
```ruby
# Connection over Unix Domain Socket
statsd = Datadog::Statsd.new(socket_path: '/path/to/socket/file')
# ...
# release resources used by the client instance
statsd.close()
```

Find a list of all the available options for your DogStatsD Client in the [DogStatsD-ruby rubydoc](https://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog/Statsd) or in the [Datadog public DogStatsD documentation](https://docs.datadoghq.com/developers/dogstatsd/?code-lang=ruby#client-instantiation-parameters).

### Migrating from v4.x to v5.x

If you are already using DogStatsD-ruby v4.x and you want to migrate to a version v5.x, the major
change concerning you is the new [threading model](#threading-model):

In practice, it means two things:

1. Now that the client is buffering metrics before sending them, you have to call `Datadog::Statsd#flush(sync: true)` if you want synchronous behavior. In most cases, this is not needed, as the sender thread will automatically flush the buffered metrics if the buffer gets full or when you are closing the instance.

2. You have to make sure you are either:

  * Using a singleton instance of the DogStatsD client instead of creating a new instance whenever you need one; this will let the buffering mechanism flush metrics regularly
  * Or properly disposing of the DogStatsD client instance when it is not needed anymore using the method `Datadog::Statsd#close`

If you have issues with the sender thread or the buffering mode, you can instantiate a client that behaves exactly as in v4.x (i.e. no sender thread and flush on every metric submission):

```ruby
# Create a DogStatsD client instance using UDP
statsd = Datadog::Statsd.new('localhost', 8125, single_thread: true, buffer_max_pool_size: 1)
# ...
statsd.close()
```

or

```ruby
# Create a DogStatsD client instance using UDS
statsd = Datadog::Statsd.new(socket_path: '/path/to/socket/file', single_thread: true, buffer_max_pool_size: 1)
# ...
statsd.close()
```

### v5.x Common Pitfalls

Version v5.x of `dogstatsd-ruby` is using a sender thread for flushing. This provides better performance, but you need to consider the following pitfalls:

1. Applications that use `fork` after having created the dogstatsd instance: the child process will automatically spawn a new sender thread to flush metrics.

2. Applications that create multiple instances of the client without closing them: it is important to `#close` all instances to free the thread and the socket they are using otherwise you will leak those resources.

If you are using [Sidekiq](https://github.com/mperham/sidekiq), please make sure to close the client instances that are instantiated. [See this example on using DogStatsD-ruby v5.x with Sidekiq](https://github.com/DataDog/dogstatsd-ruby/blob/master/examples/sidekiq_example.rb).

Applications that run into issues but can't apply these recommendations should use the `single_thread` mode which disables the use of the sender thread.
Here is how to instantiate a client in this mode:

```ruby
statsd = Datadog::Statsd.new('localhost', 8125, single_thread: true)
# ...
# release resources used by the client instance and flush last metrics
statsd.close()
```

### Origin detection over UDP

Origin detection is a method to detect which pod DogStatsD packets are coming from, in order to add the pod's tags to the tag list.

To enable origin detection over UDP, add the following lines to your application manifest:

```yaml
env:
  - name: DD_ENTITY_ID
    valueFrom:
      fieldRef:
        fieldPath: metadata.uid
```

The DogStatsD client attaches an internal tag, `entity_id`. The value of this tag is the content of the `DD_ENTITY_ID` environment variable, which is the pod’s UID.

## Usage

In order to use DogStatsD metrics, events, and Service Checks the Datadog Agent must be [running and available](https://docs.datadoghq.com/developers/dogstatsd/?tab=ruby).

### Metrics

After the client is created, you can start sending custom metrics to Datadog. See the dedicated [Metric Submission: DogStatsD documentation](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?tab=ruby) to see how to submit all supported metric types to Datadog with working code examples:

* [Submit a COUNT metric](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?code-lang=ruby#count).
* [Submit a GAUGE metric](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?code-lang=ruby#gauge).
* [Submit a SET metric](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?code-lang=ruby#set)
* [Submit a HISTOGRAM metric](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?code-lang=ruby#histogram)
* [Submit a DISTRIBUTION metric](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?code-lang=ruby#distribution)

Some options are suppported when submitting metrics, like [applying a Sample Rate to your metrics](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?tab=ruby#metric-submission-options) or [tagging your metrics with your custom tags](https://docs.datadoghq.com/metrics/dogstatsd_metrics_submission/?tab=ruby#metric-tagging). Find all the available functions to report metrics in the [DogStatsD-ruby rubydoc](https://www.rubydoc.info/github/DataDog/dogstatsd-ruby/master/Datadog/Statsd).

### Events

After the client is created, you can start sending events to your Datadog Event Stream. See the dedicated [Event Submission: DogStatsD documentation](https://docs.datadoghq.com/events/guides/dogstatsd/?code-lang=ruby) to see how to submit an event to Datadog your Event Stream.

### Service Checks

After the client is created, you can start sending Service Checks to Datadog. See the dedicated [Service Check Submission: DogStatsD documentation](https://docs.datadoghq.com/developers/service_checks/dogstatsd_service_checks_submission/?tab=ruby) to see how to submit a Service Check to Datadog.

### Maximum packet size in high-throughput scenarios

In order to have the most efficient use of this library in high-throughput scenarios,
recommended values for the maximum packet size have already been set for both UDS (8192 bytes)
and UDP (1432 bytes).

However, if are in control of your network and want to use a different value for the maximum packet
size, you can do it by setting the `buffer_max_payload_size` parameter:

```ruby
statsd = Datadog::Statsd.new('localhost', 8125, buffer_max_payload_size: 4096)
# ...
statsd.close()
```

## Threading model

Starting with version 5.0, `dogstatsd-ruby` employs a new threading model where one instance of `Datadog::Statsd` can be shared between threads and where data sending is non-blocking (asynchronous).

When you instantiate a `Datadog::Statsd`, a sender thread is spawned. This thread will be called the Sender thread, as it is modeled by the [Sender](../lib/datadog/statsd/sender.rb) class. You can make use of `single_thread: true` to disable this behavior.

This thread is stopped when you close the statsd client (`Datadog::Statsd#close`). Instantiating a lot of statsd clients without calling `#close` after they are not needed anymore will most likely lead to threads being leaked.

The sender thread has the following logic (from `Datadog::Statsd::Sender#send_loop`):

```
while the sender message queue is not closed do
  read message from sender message queue

  if message is a Control message to flush
    flush buffer in connection
  else if message is a Control message to synchronize
    synchronize with calling thread
  else
    add message to the buffer
  end
end while
```

There are three different kinds of messages:

1. a control message to flush the buffer in the connection
2. a control message to synchronize any thread with the sender thread
3. a message to append to the buffer

There is also an implicit message which closes the queue which will cause the sender thread to finish processing and exit.


```ruby
statsd = Datadog::Statsd.new('localhost', 8125)
```

The message queue's maximum size (in messages) is given by the `sender_queue_size` argument, and has appropriate defaults for UDP (2048), UDS (512) and `single_thread: true` (1).

The `buffer_flush_interval`, if enabled, is implemented with an additional thread which manages the timing of those flushes.  This additional thread is used even if `single_thread: true`.

### Usual workflow

You push metrics to the statsd client which writes them quickly to the sender message queue. The sender thread receives those message, buffers them and flushes them to the connection when the buffer limit is reached.

### Flushing

When calling `Datadog::Statsd#flush`, a specific control message (`:flush`) is sent to the sender thread. When the sender thread receives it, it flushes its internal buffer into the connection.

### Rendez-vous

It is possible to ensure a message has been consumed by the sender thread and written to the buffer by simply calling a rendez-vous right after. This is done when you are doing a synchronous flush using `Datadog::Statsd#flush(sync: true)`.

Doing so means the caller thread is blocked and waiting until the data has been flushed by the sender thread.

This is useful when preparing to exit the application or when checking unit tests.

### Thread-safety

By default, instances of `Datadog::Statsd` are thread-safe and we recommend that a single instance be reused by all application threads (even in applications that employ forking). The sole exception is the `#close` method — this method is not yet thread safe (work in progress here [#209](https://github.com/DataDog/dogstatsd-ruby/pull/209)).

When using the `single_thread: true` mode, instances of `Datadog::Statsd` are still thread-safe, but you may run into contention on heavily-threaded applications, so we don’t recommend (for performance reasons) reusing these instances.

### Delaying serialization

By default, message serialization happens synchronously whenever stat methods such as `#increment` gets called, blocking the caller. If the blocking is impacting your program's performance, you may want to consider the `delay_serialization: true` mode.

The `delay_serialization: true` mode delays the serialization of metrics to avoid the wait when submitting metrics. Serialization will still have to happen at some point, but it might be postponed until a more convenient time, such as after an HTTP request has completed.

In `single_thread: true` mode, you'll probably want to set `sender_queue_size:` from it's default of `1` to some greater value, so that it can benefit from `delay_serialization: true`. Messages will then be queued unserialized in the sender queue and processed normally whenever `sender_queue_size` is reached or `#flush` is called. You might set `sender_queue_size: Float::INFINITY` to allow for an unbounded queue that will only be processed on explicit `#flush`.

In `single_thread: false` mode, `delay_serialization: true`, will cause serialization to happen inside the sender thread.

## Versioning

This Ruby gem is using [Semantic Versioning](https://guides.rubygems.org/patterns/#semantic-versioning) but please note that supported Ruby versions can change in a minor release of this library.
As much as possible, we will add a "future deprecation" message in the minor release preceding the one dropping the support.

## Ruby Versions

This gem supports and is tested on Ruby minor versions 2.1 through 3.1.
Support for Ruby 2.0 was dropped in version 5.4.0.

## Credits

dogstatsd-ruby is forked from Rein Henrichs' [original Statsd client](https://github.com/reinh/statsd).

Copyright (c) 2011 Rein Henrichs. See LICENSE.txt for
further details.
