[![Build Status](https://travis-ci.org/skorks/nesty.png?branch=master)](https://travis-ci.org/skorks/nesty)

# Nesty

Now, when you rescue an error and then re-raise your own, you don't have to lose track of what actually occured, you can keep/nest the old error in your own and the stacktrace will reflect the cause of the original error.

## Why Use It?

When you use libraries that raise their own errors, it's not a good idea to allow these errors to bubble up through your app/library. Clients of your app/library should only have to deal with errors that belong to your app and not ones that come from libraries that your app is using. To achieve this without nested exception support, you would need to rescue the error that come from external libraries and then raise your own errors in their place. Of course, when you do this you lose the information from the original error. With nested exception support you no longer have to lose this information which is very handy.

## Installation

Add this line to your application's Gemfile:

    gem 'nesty'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nesty

## Usage

Super simple, create your own error class just like normal, but include a module in it:

```ruby
class HappyError < StandardError
  include Nesty::NestedError
end
```

Alternatively rather than inheriting from `StandardError` do this:

```ruby
class HappyError < Nesty::NestedStandardError
end
```

Instances of `HappyError`, will now support nesting another error inside.

Here is how we can use this.

```ruby
begin
  raise StandardError.new
rescue => e
  raise HappyError.new("hello", e)
end
```

That was the explicit way, you raise another error and pass in the error you rescued, but you can also do this:

```ruby
begin
  raise StandardError.new
rescue => e
  raise HappyError.new
end
```

This is the implicit way, the `HappyError` instance will still nest the `StandardError` that was rescued.

You can of course go deeper and keep rescuing and raising your own errors. As long as you raise with instances that support nesting (e.g. ones that include `Nesty::NestedError` or inherit from `Nesty::NestedStandardError`), the stack trace will include all the nested exception messages.

### What The Stacktrace Will Look Like?

It's probably a good idea to keep the stacktrace as close to a normal one as possible and in this case it actually will look very similar to a normal stacktrace. The only difference is that the error messages for all the nested errors will be included in the stacktrace (as opposed to just the message for the outer error).

Let's illustrate with an example.

We have 3 errors, A, B and C all nested in each other (A is nested in B and B is nested in C). They have the following messages and backtrace arrays:

```
A - message: 'a', backtrace: ['2', '1']
B - message: 'b', backtrace: ['4', '3', '2', '1']
C - message: 'c', backtrace: ['6', '5', '4', '3', '2', '1']
```

If C was not nested and we allowed it to bubble up so that it gets dumped to standard output, we would see something like the following:

```
c
6
5
4
3
2
1
```

But, with out nested errors we would see the following:

```
c
6
5
4: b
3
2: a
1
```

Since a stacktrace for a nested error is always a subset of the stacktrace of the enclosing error, all we need do is add the messages for each of our nested errors in the appropriate place in the stacktrace. Simple, but handy.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
