# SmartProperties

Ruby accessors on steroids.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'smart_properties'
```

And then execute:

```plain
$ bundle
```

Or install it yourself as:

```plain
$ gem install smart_properties
```

## Usage

`SmartProperties` are meant to extend standard Ruby classes. Simply include
the `SmartProperties` module and use the `property` method along with a name
and optional configuration parameters to define new properties. Calling this
method results in the generation of a getter and setter pair. In contrast to
traditional Ruby accessors -- created by calling `attr_accessor`,
`SmartProperties` provide much more functionality:

1. input conversion,
2. input validation,
3. default values, and
4. presence checking.

These features can be configured by calling the `property` method with
additional configuration parameters. The module also provides a default
implementation for a constructor that accepts a set of attributes. This is
comparable to the constructor of `ActiveRecord` objects.

Before we discuss the configuration of properties in more detail, we first
present a short synopsis of all the functionality provided by
`SmartProperties`.

### Synopsis

The example below shows how to implement a class called `Message` which has
three properties: `subject`, `body`, and `priority`. The two properties,
`subject` and `priority`, are required whereas `body` is optional.
Furthermore, all properties use input conversion. The `priority` property also
uses validation and has a default value so if it is not set during initialization
it will be set according to the default value.

```ruby
require 'rubygems'
require 'smart_properties'

class Message
  include SmartProperties

  property :subject,  converts: :to_s,
                      required: true

  property :body,     converts: :to_s

  property :priority, converts: :to_sym,
                      accepts: [:low, :normal, :high],
                      default: :normal,
                      required: true
end
```

Creating an instance of this class without specifying any attributes will
result in an `SmartProperties::InitializationError` telling you to specify the
required property `subject`.

```ruby
Message.new # => raises SmartProperties::InitializationError, "Message requires the following properties to be set: subject"
```

Creating an instance of this class with all required properties but then
setting the property `priority` to an invalid value will also result in an
`SmartProperties::InvalidValueError`. Since the property is required, assigning
`nil` is also prohibited and will result in a
`SmartProperties::MissingValueError`. All errors `SmartProperties` raises are
subclasses of `ArgumentError`.

```ruby
m = Message.new subject: 'Lorem ipsum'
m.priority # => :normal

begin
  m.priority = :urgent
rescue ArgumentError => error
  error.class # => raises SmartProperties::InvalidValueError
  error.message # => "Message does not accept :urgent as value for the property priority"
end
```

Next, we discuss the various configuration options `SmartProperties` provide.

### Property Configuration

This subsection explains the various configuration options `SmartProperties`
provide.

#### Input conversion

To automatically convert a given value for a property, you can use the
`:converts` configuration parameter. The parameter can either be a `Symbol` or
a `lambda` statement. Using a `Symbol` will instruct the setter to call the
method identified by this symbol on the object provided as input data and take
the result of this method call as value instead. The example below shows how
to implement a property that automatically converts all given input to a
`String` by calling `#to_s` on the object provided as input.

```ruby
class Article
  property :title, converts: :to_s
end
```

If you need more fine-grained control, you can use a lambda statement to
specify how the conversion should be done. The statement will be evaluated in
the context of the class defining the property and takes the given value as
input. The example below shows how to implement a property that automatically
converts all given input to a slug representation.

```ruby
class Article
  property :slug, converts: lambda { |slug| slug.downcase.gsub(/\s+/, '-').gsub(/\W/, '') }
end
```

#### Input validation

To ensure that a given value for a property is always of a certain type, you
can specify the `:accepts` configuration parameter. This will result in an
automatic validation whenever the setter for a certain property is called. The
example below shows how to implement a property which only accepts instances
of type `String` as input.

```ruby
class Article
  property :title, accepts: String
end
```

Instead of using a class, you can also use a list of permitted values. The
example below shows how to implement a property that only accepts `true` or
`false` as values.

```ruby
class Article
  property :published, accepts: [true, false]
end
```

You can also use a `lambda` statement for input validation if a more complex
validation procedure is required. The `lambda` statement is evaluated in the
context of the class that defines the property and receives the given value as
input. The example below shows how to implement a property called title that
only accepts values which match the given regular expression.

```ruby
class Article
  property :title, accepts: lambda { |title| /^Lorem \w+$/ =~ title }
end
```

There are also a set of common validation helpers you may use. These common
cases are provided to help avoid rewriting validation logic that occurs
often. These validations can be found in the `SmartProperties::Validations` module.

```ruby
class Article
  property :view_count, accepts: Ancestor.must_be(type: Number)
end
```

#### Default values

There is also support for default values. Simply use the `:default`
configuration parameter to configure a default value for a certain property.
The example below demonstrates how to implement a property that has 42 as
default value.

```ruby
class Article
  property :id, default: 42
end
```

Default values can also be specified using blocks which are evaluated at
runtime and only if no value was supplied.

#### Presence checking

To ensure that a property is always set and never `nil`, you can use the
`:required` configuration parameter. If present, this parameter will instruct
the setter of a property to not accept nil as input. The example below shows
how to implement a property that may not be `nil`.

```ruby
class Article
  property :title, required: true
end
```

Alternatively you can also use the `property!` method.

```ruby
class Article
  property! :title
end
```

The decision whether or not a property is required can also be delayed and
evaluated at runtime by providing a block instead of a boolean value. The
example below shows how to implement a class that has two properties, `name`
and `anonoymous`. The `name` is only required if `anonymous` is set to `false`.

```ruby
class Person
  property :name, required: lambda { not anonymous }
  property :anonymous, required: true, default: true, accepts: [true, false]
end
```

#### Custom reader naming

In Ruby, predicate methods by convention end with a `?`.
This convention is violated in the example above, but can easily be fixed by supplying a custom `reader` name:

```ruby
class Person
  property :name, required: lambda { not anonymous }
  property :anonymous, required: true, default: true, accepts: [true, false], reader: :anonymous?
end
```

To ensure backwards compatibility, boolean properties do not automatically change their reader name.
It is thus your responsibility to configure the property properly.

#### Custom reader implementation

For convenience, it is possible to use the `super` method to access the original reader when overriding a reader.
This is recommended over direct access to the instance variable.

```ruby
class Person
  property :name
  property! :address

  def name
    super || address.name
  end
end
```

### Constructor argument forwarding

The `SmartProperties` initializer forwards anything to the super constructor
it does not process itself. This is true for all positional arguments
and those keyword arguments that do not correspond to a property. The example
below demonstrates how Ruby's `SimpleDelegator` in conjunction with
`SmartProperties` can be used to quickly construct a very flexible presenter.

```ruby
class PersonPresenter < SimpleDelegator
  include SmartProperties
  property :name_formatter, accepts: Proc,
                            required: true,
                            default: lambda { |p| "#{p.firstname} #{p.lastname}" }

  def full_name
    name_formatter.call(self)
  end
end

person = OpenStruct.new(firstname: "John", lastname: "Doe")
presenter = PersonPresenter.new(person)
presenter.full_name # => "John Doe"

# Changing the format is easy
presenter.name_formatter = lambda { |p| "#{p.lastename}, #{p.firstname}" }
presenter.full_name # => "Doe, John"
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
