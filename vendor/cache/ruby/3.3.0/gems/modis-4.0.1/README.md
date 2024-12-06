[![Build Status](https://travis-ci.org/rpush/modis.svg?branch=master)](https://travis-ci.org/rpush/modis)
[![Code Climate](https://codeclimate.com/github/ileitch/modis/badges/gpa.svg)](https://codeclimate.com/github/ileitch/modis)
[![Test Coverage](https://codeclimate.com/github/ileitch/modis/badges/coverage.svg)](https://codeclimate.com/github/ileitch/modis)

# Modis

ActiveModel + Redis with the aim to mimic ActiveRecord where possible.

## Requirements

Modis 4.0+ supports Rails 5.2 and higher, including Rails 6.1, as well as Ruby 2.3 and above, including Ruby 3.0. Tests are also being run with JRuby. For details please check the current CI setup.

For releases supporting older Rails versions such as 4.2-5.1 please check out the 3.x releases.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'modis'
```

And then execute:

```console
$ bundle
```

Or install it yourself as:

```console
$ gem install modis
```

## Usage

```ruby
class MyModel
  include Modis::Model
  attribute :name, :string
  attribute :age, :integer
end

MyModel.create!(name: 'Ian', age: 28)
```

### all index

Modis, by default, creates an `all` index in redis in which it stores all the IDs for records created. As a result, a large amount of memory will be consumed if many ids are stored. The `all` index functionality can be turned off by using `enable_all_index`

```ruby
class MyModel
  include Modis::Model
  enable_all_index false
end
```

By disabling the `all` index functionality, the IDs of each record created won't be saved. As a side effect, using `all` finder method will raise a `IndexError` exception as we would not have enough information to fetch all records. See https://github.com/rpush/modis/pull/7 for more context.

## Supported Features

TODO.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
