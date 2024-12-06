## Introduction

CGI is a large class, providing several categories of methods, many of which
are mixed in from other modules.  Some of the documentation is in this class,
some in the modules CGI::QueryExtension and CGI::HtmlExtension.  See
CGI::Cookie for specific information on handling cookies, and cgi/session.rb
(CGI::Session) for information on sessions.

For queries, CGI provides methods to get at environmental variables,
parameters, cookies, and multipart request data.  For responses, CGI provides
methods for writing output and generating HTML.

Read on for more details.  Examples are provided at the bottom.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cgi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cgi

## Usage

### Get form values

```ruby
require "cgi"
cgi = CGI.new
value = cgi['field_name']   # <== value string for 'field_name'
  # if not 'field_name' included, then return "".
fields = cgi.keys            # <== array of field names

# returns true if form has 'field_name'
cgi.has_key?('field_name')
cgi.has_key?('field_name')
cgi.include?('field_name')
```

CAUTION! cgi['field_name'] returned an Array with the old
cgi.rb(included in Ruby 1.6)

### Get form values as hash

```ruby
require "cgi"
cgi = CGI.new
params = cgi.params
```

cgi.params is a hash.

```ruby
cgi.params['new_field_name'] = ["value"]  # add new param
cgi.params['field_name'] = ["new_value"]  # change value
cgi.params.delete('field_name')           # delete param
cgi.params.clear                          # delete all params
```

### Save form values to file

```ruby
require "pstore"
db = PStore.new("query.db")
db.transaction do
  db["params"] = cgi.params
end
```


### Restore form values from file

```ruby
require "pstore"
db = PStore.new("query.db")
db.transaction do
  cgi.params = db["params"]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/cgi.
