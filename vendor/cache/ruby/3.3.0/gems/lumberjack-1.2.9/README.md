![Continuous Integration](https://github.com/bdurand/lumberjack/workflows/Continuous%20Integration/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/a0abc03721fff9b0cde1/maintainability)](https://codeclimate.com/github/bdurand/lumberjack/maintainability)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

# Lumberjack

Lumberjack is a simple, powerful, and fast logging implementation in Ruby. It uses nearly the same API as the Logger class in the Ruby standard library and as ActiveSupport::BufferedLogger in Rails.

## Usage

This code aims to be extremely simple to use. The core interface is the Lumberjack::Logger which is used to log messages (which can be any object) with a specified Severity. Each logger has a level associated with it and messages are only written if their severity is greater than or equal to the level.

```ruby
  logger = Lumberjack::Logger.new("logs/application.log")  # Open a new log file with INFO level
  logger.info("Begin request")
  logger.debug(request.params)  # Message not written unless the level is set to DEBUG
  begin
    # do something
  rescue => exception
    logger.error(exception)
    raise
  end
  logger.info("End request")
```

This is all you need to know to log messages.

## Features

### Meta data

When messages are added to the log, additional data about the message is kept in a Lumberjack::LogEntry. This means you don't need to worry about adding the time or process id to your log messages as they will be automatically recorded.

The following information is recorded for each message:

* severity - The severity recorded for the message.
* time - The time at which the message was recorded.
* program name - The name of the program logging the message. This can be either set for all messages or customized with each message.
* process id - The process id (pid) of the process that logged the message.
* tags - An map of name value pairs for addition information about the log context.

### Tags

You can use tags to provide additional meta data about a log message or the context that the log message is being made in. Using tags can keep your log messages clean. You can avoid string interpolation to add additional meta data.

Each of the logger methods includes an additional argument that can be used to specify tags on a messsage:

```ruby
logger.info("request completed", duration: elapsed_time, status: response.status)
```

You can also specify tags on a logger that will be included with every log message.

```ruby
logger.tag(host: Socket.gethostname)
```

You can specify tags that will only be applied to the logger in a block as well.

```ruby
logger.tag(thread_id: Thread.current.object_id) do
  logger.info("here") # Will include the `thread_id` tag
  logger.tag(count: 15)
  logger.info("with count") # Will include the `count` tag
end
logger.info("there") # Will not include the `thread_id` or `count` tag
```

You can also set tags to `Proc` objects that will be evaluated when creating a log entry.

```ruby
logger.tag(thread_id: lambda { Thread.current.object_id })
Thread.new do
  logger.info("inside thread") # Will include the `thread_id` tag with id of the spawned thread
end
logger.info("outside thread") # Will include the `thread_id` tag with id of the main thread
```

Finally, you can specify a logging context with tags that apply within a block to all loggers.

```ruby
Lumberjack.context do
  Lumberjack.tag(request_id: SecureRandom.hex)
  logger.info("begin request") # Will include the `request_id` tag
end
logger.info("no requests") # Will not include the `request_id` tag
```

Tag keys are always converted to strings. Tags are inherited so that message tags take precedence over block tags which take precedence over global tags.

#### Compatibility with ActiveSupport::TaggedLogging

`Lumberjack::Logger` version 1.1.2 or greater is compatible with `ActiveSupport::TaggedLogging`. This is so that other code that expect to have a logger that responds to the `tagged` method will work. Any tags added with the `tagged` method will be appended to an array in the the "tagged" tag.

```ruby
logger.tagged("foo", "bar=1", "other") do
  logger.info("here") # will include tags: {"tagged" => ["foo", "bar=1", "other"]}
end
```

#### Templates

The built in `Lumberjack::Device::Writer` class has built in support for including tags in the output using the `Lumberjack::Template` class.

You can specify any tag name you want in a template as well as the `:tags` macro for all tags. If a tag name has been used as it's own macro, it will not be included in the `:tags` macro.

#### Unit Of Work

Lumberjack 1.0 had a concept of a unit of work id that could be used to tie log messages together. This has been replaced by tags. There is still an implementation of `Lumberjack.unit_of_work`, but it is just a wrapper on the tag implementation.

### Pluggable Devices

When a Logger logs a LogEntry, it sends it to a Lumberjack::Device. Lumberjack comes with a variety of devices for logging to IO streams or files.

* Lumberjack::Device::Writer - Writes log entries to an IO stream.
* Lumberjack::Device::LogFile - Writes log entries to a file.
* Lumberjack::Device::DateRollingLogFile - Writes log entries to a file that will automatically roll itself based on date.
* Lumberjack::Device::SizeRollingLogFile - Writes log entries to a file that will automatically roll itself based on size.
* Lumberjack::Device::Multi - This device wraps mulitiple other devices and will write log entries to each of them.
* Lumberjack::Device::Null - This device produces no output and is intended for testing environments.

If you'd like to send you log to a different kind of output, you just need to extend the Device class and implement the +write+ method. Or check out these plugins:

* [lumberjack_syslog_device](https://github.com/bdurand/lumberjack_syslog_device) - send your log messages to the system wide syslog service
* [lumberjack_mongo_device](https://github.com/bdurand/lumberjack_mongo_device) - store your log messages to a [MongoDB](http://www.mongodb.org/) NoSQL data store
* [lumberjack-couchdb-driver](https://github.com/narkisr/lumberjack-couchdb-driver) - store your log messages to a [CouchDB](http://couchdb.apache.org/) NoSQL data store
* [lumberjack_heroku_device](https://github.com/tonycoco/lumberjack_heroku_device) - log to Heroku's logging system

### Customize Formatting

#### Formatters

The message you send to the logger can be any object type and does not need to be a string. You can specify a `Lumberjack::Formatter` to instruct the logger how to format objects before outputting them to the device. You do this by mapping classes or modules to formatter code. This code can be either a block or an object that responds to the `call` method. The formatter will be called with the object logged as the message and the returned value will be what is sent to the device.

```ruby
  # Format all floating point number with three significant digits.
  logger.formatter.add(Float) { |value| value.round(3) }

  # Format all enumerable objects as a comma delimited string.
  logger.formatter.add(Enumerable) { |value| value.join(", ") }
```

There are several built in classes you can add as formatters. You can use a symbol to reference built in formatters.

```ruby
  logger.formatter.add(Hash, :pretty_print)  # use the Formatter::PrettyPrintFormatter for all Hashes
  logger.formatter.add(Hash, Lumberjack::Formatter::PrettyPrintFormatter.new)  # alternative using a formatter instance
```

* `:object` - `Lumberjack::Formatter::ObjectFormatter` - no op conversion that returns the object itself.
* `:string` - `Lumberjack::Formatter::StringFormatter` - calls `to_s` on the object.
* `:strip` - `Lumberjack::Formatter::StripFormatter` - calls `to_s.strip` on the object.
* `:inspect` - `Lumberjack::Formatter::InspectFormatter` - calls `inspect` on the object.
* `:exception` - `Lumberjack::Formatter::ExceptionFormatter` - special formatter for exceptions which logs them as multi line statements with the message and backtrace.
* `:date_time` - `Lumberjack::Formatter::DateTimeFormatter` - special formatter for dates and times to format them using `strftime`.
* `:pretty_print` - `Lumberjack::Formatter::PrettyPrintFormatter` - returns the pretty print format of the object.
* `:id` - `Lumberjack::Formatter::IdFormatter` - returns a hash of the object with keys for the id attribute and class.
* `:structured` - `Lumberjack::Formatter::StructuredFormatter` - crawls the object and applies the formatter recursively to Enumerable objects found in it (arrays, hashes, etc.).

To define your own formatter, either provide a block or an object that responds to `call` with a single argument.

The default formatter will pass through values for strings, numbers, and booleans, and use the `:inspect` formatter for all objects except for exceptions which will be formatted with the `:exception` formatter.

#### Tag Formatters

The `logger.formatter` will only apply to log messages. You can use `logger.tag_formatter` to register formatters for tags. You can register both default formatters that will apply to all tag values, as well as tag specifice formatters that will apply only to objects with a specific tag name.

The fomatter values can be either a `Lumberjack::Formatter` or a block or an object that responds to `call`. If you supply a `Lumberjack::Formatter`, the tag value will be passed through the rules for that formatter. If you supply a block or other object, it will be called with the tag value.

```ruby
# These will all do the same thing formatting all tag values with `inspect`
logger.tag_formatter.default(Lumberjack::Formatter.new.clear.add(Object, :inspect))
logger.tag_formatter.default(Lumberjack::Formatter::InspectFormatter.new)
logger.tag_formatter.default { |value| value.inspect }

# This will register formatters only on specific tag names
logger.tag_formatter.add(:thread) { |thread| "Thread(#{thread.name})" }
logger.tag_formatter.add(:current_user, Lumberjack::Formatter::IdFormatter.new)
```

#### Templates

If you use the built in `Lumberjack::Writer` derived devices, you can also customize the Template used to format the LogEntry.

See `Lumberjack::Template` for a complete list of macros you can use in the template. You can also use a block that receives a `Lumberjack::LogEntry` as a template.

```ruby
  # Change the format of the time in the log
  Lumberjack::Logger.new("application.log", :time_format => "%m/%d/%Y %H:%M:%S")

  # Use a simple template that only includes the time and the message
  Lumberjack::Logger.new("application.log", :template => ":time - :message")

  # Use a simple template that includes tags, but handles the `duration` tag separately.
  # All tags will appear at the end of the message except for `duration` which will be at the beginning.
  Lumberjack::Logger.new("application.log", :template => ":time (:duration) - :message - :tags")

  # Use a custom template as a block that only includes the first character of the severity
  template = lambda{|e| "#{e.severity_label[0, 1]} #{e.time} - #{e.message}"}
  Lumberjack::Logger.new("application.log", :template => template)
```

### Buffered Logging

The logger has hooks for devices that support buffering to potentially increase performance by batching physical writes. Log entries are not guaranteed to be written until the Lumberjack::Logger#flush method is called. Buffering can improve performance if I/O is slow or there high overhead writing to the log device.

You can use the `:flush_seconds` option on the logger to periodically flush the log. This is usually a good idea so you can more easily debug hung processes. Without periodic flushing, a process that hangs may never write anything to the log because the messages are sitting in a buffer. By turning on periodic flushing, the logged messages will be written which can greatly aid in debugging the problem.

The built in stream based logging devices use an internal buffer. The size of the buffer (in bytes) can be set with the `:buffer_size` options when initializing a logger. The default behavior is to not to buffer.

```ruby
  # Set buffer to flush after 8K has been written to the log.
  logger = Lumberjack::Logger.new("application.log", :buffer_size => 8192)

  # Turn off buffering so entries are immediately written to disk.
  logger = Lumberjack::Logger.new("application.log", :buffer_size => 0)
```

### Automatic Log Rolling

The built in devices include two that can automatically roll log files based either on date or on file size. When a log file is rolled, it will be renamed with a suffix and a new file will be created to receive new log entries. This can keep your log files from growing to unusable sizes and removes the need to schedule an external process to roll the files.

There is a similar feature in the standard library Logger class, but the implementation here is safe to use with multiple processes writing to the same log file.

## Difference Standard Library Logger

`Lumberjack::Logger` does not extend from the `Logger` class in the standard library, but it does implement a compantible API. The main difference is in the flow of how messages are ultimately sent to devices for output.

The standard library Logger logic converts the log entries to strings and then sends the string to the device to be written to a stream. Lumberjack, on the other hand, sends structured data in the form of a `Lumberjack::LogEntry` to the device and lets the device worry about how to format it. The reason for this flip is to better support structured data logging. Devices (even ones that write to streams) can format the entire payload including non-string objects and tags however they need to.

The logging methods (`debug`, 'info', 'warn', 'error', 'fatal') are overloaded with an additional argument for setting tags on the log entry.

## Examples

These example are for Rails applications, but there is no dependency on Rails for using this gem. Most of the examples are applicable to any Ruby application.

In a Rails application you can replace the default production logger by adding this to your config/environments/production.rb file:

```ruby
  # Use the ActionDispatch request id as the unit of work id. This will use just the first chunk of the request id.
  # If you want to use an abbreviated request id for terseness, change the last argument to `true`
  config.middleware.insert_after ActionDispatch::RequestId, Lumberjack::Rack::RequestId, false
  # Use a custom unit of work id to each request
  # config.middleware.insert(0, Lumberjack::Rack::UnitOfWork)
  # Change the logger to use Lumberjack
  log_file_path = Rails.root + "log" + "#{Rails.env}.log"
  config.logger = Lumberjack::Logger.new(log_file, :level => :warn)
```

To set up a logger to roll every day at midnight, you could use this code (you can also specify :weekly or :monthly):

```ruby
  config.logger = Lumberjack::Logger.new(log_file_path, :roll => :daily)
```

To set up a logger to roll log files when they get to 100Mb, you could use this:

```ruby
  config.logger = Lumberjack::Logger.new(log_file_path, :max_size => 100.megabytes)
```

To change the log message format, you could use this code:

```ruby
  config.logger = Lumberjack::Logger.new(log_file_path, :template => ":time - :message")
```

To change the log message format to output JSON, you could use this code:

```ruby
  config.logger = Lumberjack::Logger.new(log_file_path, :template => lambda{|e| JSON.dump(time: e.time, level: e.severity_label, message: e.message)})
```

To send log messages to syslog instead of to a file, you could use this (require the lumberjack_syslog_device gem):

```ruby
  config.logger = Lumberjack::Logger.new(Lumberjack::SyslogDevice.new)
```
