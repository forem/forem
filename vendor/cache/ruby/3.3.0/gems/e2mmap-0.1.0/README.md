# Exception2MessageMapper

Helper module for easily defining exceptions with predefined messages.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'e2mmap'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install e2mmap

## Usage

1.

```
class Foo
  extend Exception2MessageMapper
  def_e2message ExistingExceptionClass, "message..."
  def_exception :NewExceptionClass, "message..."[, superclass]
  ...
end
```

2.

```
module Error
  extend Exception2MessageMapper
  def_e2message ExistingExceptionClass, "message..."
  def_exception :NewExceptionClass, "message..."[, superclass]
  ...
end

class Foo
  include Error
  ...
end

foo = Foo.new
foo.Fail ....
```

3.

```
module Error
  extend Exception2MessageMapper
  def_e2message ExistingExceptionClass, "message..."
  def_exception :NewExceptionClass, "message..."[, superclass]
  ...
end

class Foo
  extend Exception2MessageMapper
  include Error
  ...
end

Foo.Fail NewExceptionClass, arg...
Foo.Fail ExistingExceptionClass, arg...
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/e2mmap.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
