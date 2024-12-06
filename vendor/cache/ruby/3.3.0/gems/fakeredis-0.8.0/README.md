# FakeRedis [![Build Status](https://secure.travis-ci.org/guilleiguaran/fakeredis.png)](http://travis-ci.org/guilleiguaran/fakeredis)
This a fake implementation of redis-rb for machines without Redis or test environments


## Installation

Install the gem:

    gem install fakeredis

Add it to your Gemfile:

    gem "fakeredis"


## Versions

FakeRedis currently supports redis-rb v3 or later, if you are using
redis-rb v2.2 install the version 0.3.x:

    gem install fakeredis -v "~> 0.3.0"

or use the branch 0-3-x on your Gemfile:

    gem "fakeredis", :git => "git://github.com/guilleiguaran/fakeredis.git", :branch => "0-3-x"


## Usage

You can use FakeRedis without any changes:

```
    require "fakeredis"

    redis = Redis.new

    >> redis.set "foo", "bar"
    => "OK"

    >> redis.get "foo"
    => "bar"
```

Read [redis-rb](https://github.com/redis/redis-rb) documentation and
[Redis](http://redis.io) homepage for more info about commands

## Usage with RSpec

Require this either in your Gemfile or in RSpec's support scripts. So either:

```ruby
# Gemfile
group :test do
  gem "rspec"
  gem "fakeredis", :require => "fakeredis/rspec"
end
```

Or:

```ruby
# spec/support/fakeredis.rb
require 'fakeredis/rspec'
```

## Usage with Minitest

Require this either in your Gemfile or in Minitest's support scripts. So
either:

```ruby
# Gemfile
group :test do
  gem "minitest"
  gem "fakeredis", :require => "fakeredis/minitest"
end
```

Or:

```ruby
# test/test_helper.rb (or test/minitest_config.rb)
require 'fakeredis/minitest'
```

## Acknowledgements

Thanks to [all contributors](https://github.com/guilleiguaran/fakeredis/graphs/contributors), specially to [Caius Durling](https://github.com/caius) the most active one.

## Contributing to FakeRedis

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


## Copyright

Copyright (c) 2011-2018 Guillermo Iguaran. See LICENSE for
further details.
