# brpoplpush-redis_script

Bring your own LUA scripts into redis

![RSpec Status](https://github.com/brpoplpush/brpoplpush-redis_script/actions/workflows/rspec.yml/badge.svg) [![Maintainability](https://api.codeclimate.com/v1/badges/3770a079b380d50c3d50/maintainability)](https://codeclimate.com/github/brpoplpush/brpoplpush-redis_script/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/3770a079b380d50c3d50/test_coverage)](https://codeclimate.com/github/brpoplpush/brpoplpush-redis_script/test_coverage) [![Gem Version](https://badge.fury.io/rb/brpoplpush-redis_script.svg)](https://badge.fury.io/rb/brpoplpush-redis_script)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'brpoplpush-redis_script'
```

And then execute:

`bundle`

Or install it yourself as:

`gem install brpoplpush-redis_script`

## Usage

If you want to avoid global state in your project/gem the recommended way to use `RedisScript` is the following way.

Include the DSL module from the gem and configure with a path. We don't believe it is a good idea to put all your lua files in a single directory. We rather believe that these scripts should be placed and organized by feature.

Let's take sidekiq-unique-jobs for example. It uses `brpoplpush-redis_script` like follows:

```ruby
# lib/my_redis_scripts.rb
require "brpoplpush/redis_script"

module SidekiqUniqueJobs::Scripts
  include Brpoplpush::RedisScript::DSL

  configure do |config|
    config.scripts_path = Rails.root.join("app", "lua")
  end
end

SidekiqUniqueJobs::Scripts.execute(:lock, Redis.new, keys: ["key1", "key2"] argv: ["bogus"])
# => 1

SidekiqUniqueJobs::Scripts.execute(:lock, Redis.new, keys: ["key1", "key1"] argv: ["bogus"])
# => -1
```

```lua
-- app/lua/lock.lua

local key_one = KEYS[1]
local key_two = KEYS[2]

local locked_val = ARGV[1]

if not key_one == key_two then
  redis.call("SET", key_two, )
  return 1
end

return -1
```

This is a very simplified version of course.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/bropoplpush/brpoplpush-redis_script](https://github.com/bropoplpush/brpoplpush-redis_script). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Brpoplpush::RedisScript project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/brpoplpush-redis_script/blob/master/CODE_OF_CONDUCT.md).
