[![Build Status](https://travis-ci.org/e2/nenv.png?branch=master)](https://travis-ci.org/e2/nenv)
[![Gem Version](http://img.shields.io/gem/v/nenv.svg)](http://badge.fury.io/rb/nenv)
[![Dependency Status](https://gemnasium.com/e2/nenv.svg)](https://gemnasium.com/e2/nenv)
[![Code Climate](https://codeclimate.com/github/e2/nenv/badges/gpa.svg)](https://codeclimate.com/github/e2/nenv)
[![Coverage Status](https://coveralls.io/repos/e2/nenv/badge.png)](https://coveralls.io/r/e2/nenv)

# Nenv

Using ENV in Ruby is like using raw SQL statements - it feels wrong, because it is.

If you agree, this gem is for you.

## The benefits over using ENV directly:

- much friendlier stubbing in tests
- you no longer have to care whether false is "0" or "false" or whatever
- NO MORE ALL CAPS EVERYWHERE!
- keys become methods
- namespaces which can be passed around as objects
- you can subclass!
- you can marshal/unmarshal your own types automatically!
- strict mode saves you from doing validation yourself
- and there's more to come...

Other benefits (and compared to other solutions):
- should still work with Ruby 1.8 (in case anyone is still stuck with it)
- it's designed to be as lightweight and as fast as possible compared to ENV
- designed to be both hackable and convenient

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nenv', '~> 0.1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nenv


## Examples !!!


### Automatic booleans

You no longer have to care whether the value is "0" or "false" or "no" or "FALSE" or ... whatever

```ruby
# Without Nenv
t.verbose = (ENV['CI'] == 'true')
ok = ENV['RUBYGEMS_GEMDEPS'] == "1" || ENV.key?('BUNDLE_GEMFILE')
ENV['DEBUG'] = "true"

```

now becomes:

```ruby
t.verbose = Nenv.ci?
gemdeps = Nenv.rubygems_gemdeps? || Nenv.bundle_gemfile?
Nenv.debug = true
```

### "Namespaces"

```ruby
# Without Nenv
puts ENV['GIT_BROWSER']
puts ENV['GIT_PAGER']
puts ENV['GIT_EDITOR']
```

now becomes:

```ruby
git = Nenv :git
puts git.browser
puts git.pager
puts git.editor
```

Or in block form

```ruby
Nenv :git do |git|
  puts git.browser
  puts git.pager
  puts git.editor
end
```

### Custom type handling

```ruby
# Code without Nenv
paths = [ENV['GEM_HOME`]] + ENV['GEM_PATH'].split(':')
enable_logging if Integer(ENV['WEB_CONCURRENCY']) > 1
mydata = YAML.load(ENV['MY_DATA'])
ENV['VERBOSE'] = debug ? "1" : nil
```

can become:

```ruby
# setup
gem = Nenv :gem
gem.instance.create_method(:path) { |p| p.split(':') }

web = Nenv :web
web.instance.create_method(:concurrency) { |c| Integer(c) }

my = Nenv :my
my.instance.create_method(:data) { |d| YAML.load(d) }

Nenv.instance.create_method(:verbose=) { |v| v ? 1 : nil }

# and then you can simply do:

paths = [gem.home] + gem.path
enable_logging if web.concurrency > 1
mydata = my.data
Nenv.verbose = debug
```

### Automatic conversion to string

```ruby
ENV['RUBYGEMS_GEMDEPS'] = 1  # TypeError: no implicit conversion of Fixnum (...)
```

Nenv automatically uses `to_s`:

```ruby
Nenv.rubygems_gemdeps = 1  # no problem here
```


### Custom assignment

```ruby
data = YAML.load(ENV['MY_DATA'])
data[:foo] = :bar
ENV['MY_DATA'] = YAML.dump(data)
```

can now become:

```ruby
my = Nenv :my
my.instance.create_method(:data) { |d| YAML.load(d) }
my.instance.create_method(:data=) { |d| YAML.dump(d) }

data = my.data
data[:foo] = :bar
my.data = data
```

### Strict mode

```ruby
# Without Nenv
fail 'home not allowed' if ENV['HOME'] = Dir.pwd  # BUG! Assignment instead of comparing!
puts ENV['HOME'] # Now contains clobbered value
```

Now, clobbering can be prevented:

```ruby
env = Nenv::Environment.new
env.create_method(:home)

fail 'home not allowed' if env.home = Dir.pwd  # Fails with NoMethodError
puts env.home # works
```

### Mashup mode

You can first define all the load/dump logic globally in one place

```ruby
Nenv.instance.create_method(:web_concurrency) { |d| Integer(d) }
Nenv.instance.create_method(:web_concurrency=)
Nenv.instance.create_method(:path) { |p| Pathname(p.split(File::PATH_SEPARATOR)) }
Nenv.instance.create_method(:path=) { |array| array.map(&:to_s).join(File::PATH_SEPARATOR) }

# And now, anywhere in your app:

Nenv.web_concurrency += 3
Nenv.path += Pathname.pwd + "foo"

```

### Your own class (recommended version for simpler unit tests)

```ruby
MyEnv = Nenv::Builder.build do
  create_method(:foo?)
end

MyEnv.new('my').foo? # same as ENV['MY_FOO'][/^(?:false|no|n|0)/i,1].nil?

```


### Your own class (dynamic version - not recommended because harder to test)

```ruby
class MyEnv < Nenv::Environment
  def initialize
    super("my")
    create_method(:foo?)
  end
end

MyEnv.new.foo? # same as ENV['MY_FOO'][/^(?:false|no|n|0)/i,1].nil?

```


## NOTES

Still, avoid using environment variables if you can.

At least, avoid actually setting them - especially in multithreaded apps.

As for Nenv, while you can access the same variable with or without namespaces,
filters are tied to instances, e.g.:

```ruby
Nenv.instance.create_method(:foo_bar) { |d| Integer(d) }
Nenv('foo').instance.create_method(:bar) { |d| Float(d) }
env = Nenv::Environment.new(:foo).tap { |e| e.create_method(:bar) }
```

all work on the same variable, but each uses a different filter for reading the value.


## Documentation / SemVer / API

Any behavior not mentioned here (in this README) is subject to change. This
includes module names, class names, file names, method names, etc.

If you are relying on behavior not documented here, please open a ticket.


## What's wrong with ENV?

Well sure, having ENV act like a Hash is much better than calling "getenv".

Unfortunately, the advantages of using ENV make no sense:

- it's faster but ... environment variables are rarely used thousands of times in tight loops
- it's already an object ... but there's not much you can do with it (try ENV.class)
- it's globally available ... but you can't isolate it in tests (you need to reset it every time)
- you can use it to set variables ... but it's named like a const
- it allows you to use keys regardless of case ... but by convention lowercase shouldn't be used except for local variables (which are only really used by shell scripts)
- it's supposed to look ugly to discourage use ... but often your app/gem is forced to use 3rd party environment variables anyway
- it's a simple Hash-like class ... but either you encapsulate it in your own classes - or all the value mapping/validation happens everywhere you want the data (yuck!)


But the BIGGEST disadvantage is in specs, e.g.:

```ruby
allow(ENV).to receive(:[]).with('MY_VARIABLE').and_return("foo")
allow(ENV).to receive(:[]=).with('MY_VARIABLE', "foo bar")
# (and if you get the above wrong, you may be debugging for a long, long time...)
```

which could instead be completely isolated as (and without side effects):

```ruby
allow(env).to receive(:variable).and_return("foo")
expect(env).to receive(:variable=).with("foo bar")
# (with verifying doubles it's hard to get it wrong and get stuck)
```

Here's a full example:

```ruby
# In your implementation
MyEnv = Nenv::Builder.build do
  create_method(:variable)
  create_method(:variable=)
end

class Foo
  def foo
    MyEnv.new(:my).variable += "bar"
  end
end

# Stubbing the class in your specs
RSpec.describe Foo do
  let(:env) { instance_double(MyEnv) }
  before { allow(MyEnv).to receive(:new).with(:my).and_return(env) }

  describe "#foo" do
    before { allow(env).to receive(:variable).and_return("foo") }

    it "appends a value" do
      expect(env).to receive(:variable=).with("foo bar")
      subject.foo
    end
  end
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/nenv/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
