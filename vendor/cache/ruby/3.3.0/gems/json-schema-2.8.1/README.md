[![Gem Version](https://badge.fury.io/rb/json-schema.svg)](https://badge.fury.io/rb/json-schema)
[![Travis](https://travis-ci.org/ruby-json-schema/json-schema.svg?branch=master)](https://travis-ci.org/ruby-json-schema/json-schema)
[![Code Climate](https://codeclimate.com/github/ruby-json-schema/json-schema/badges/gpa.svg)](https://codeclimate.com/github/ruby-json-schema/json-schema)

Ruby JSON Schema Validator
==========================

This library is intended to provide Ruby with an interface for validating JSON
objects against a JSON schema conforming to [JSON Schema Draft
4](http://tools.ietf.org/html/draft-zyp-json-schema-04). Legacy support for
[JSON Schema Draft 3](http://tools.ietf.org/html/draft-zyp-json-schema-03),
[JSON Schema Draft 2](http://tools.ietf.org/html/draft-zyp-json-schema-02), and
[JSON Schema Draft 1](http://tools.ietf.org/html/draft-zyp-json-schema-01) is
also included.

Additional Resources
--------------------

- [Google Groups](https://groups.google.com/forum/#!forum/ruby-json-schema)
- #ruby-json-schema on chat.freenode.net

Version 2.0.0 Upgrade Notes
---------------------------

Please be aware that the upgrade to version 2.0.0 will use Draft-04 **by
default**, so schemas that do not declare a validator using the `$schema`
keyword will use Draft-04 now instead of Draft-03. This is the reason for the
major version upgrade.

Installation
------------

From rubygems.org:

```sh
gem install json-schema
```

From the git repo:

```sh
$ gem build json-schema.gemspec
$ gem install json-schema-2.5.2.gem
```

Validation
-----

Three base validation methods exist:

1. `validate`: returns a boolean on whether a validation attempt passes
2. `validate!`: throws a `JSON::Schema::ValidationError` with an appropriate message/trace on where the validation failed
3. `fully_validate`: builds an array of validation errors return when validation is complete

All methods take two arguments, which can be either a JSON string, a file
containing JSON, or a Ruby object representing JSON data. The first argument to
these methods is always the schema, the second is always the data to validate.
An optional third options argument is also accepted; available options are used
in the examples below.

By default, the validator uses the [JSON Schema Draft
4](http://tools.ietf.org/html/draft-zyp-json-schema-04) specification for
validation; however, the user is free to specify additional specifications or
extend existing ones. Legacy support for Draft 1, Draft 2, and Draft 3 is
included by either passing an optional `:version` parameter to the `validate`
method (set either as `:draft1` or `draft2`), or by declaring the `$schema`
attribute in the schema and referencing the appropriate specification URI. Note
that the `$schema` attribute takes precedence over the `:version` option during
parsing and validation.

For further information on json schema itself refer to <a
href="http://spacetelescope.github.io/understanding-json-schema/">Understanding
JSON Schema</a>.

Basic Usage
--------------

```ruby
require "json-schema"

schema = {
  "type" => "object",
  "required" => ["a"],
  "properties" => {
    "a" => {"type" => "integer"}
  }
}

#
# validate ruby objects against a ruby schema
#

# => true
JSON::Validator.validate(schema, { "a" => 5 })
# => false
JSON::Validator.validate(schema, {})

#
# validate a json string against a json schema file
#

require "json"
File.write("schema.json", JSON.dump(schema))

# => true
JSON::Validator.validate('schema.json', '{ "a": 5 }')

#
# raise an error when validation fails
#

# => "The property '#/a' of type String did not match the following type: integer"
begin
  JSON::Validator.validate!(schema, { "a" => "taco" })
rescue JSON::Schema::ValidationError => e
  e.message
end

#
# return an array of error messages when validation fails
#

# => ["The property '#/a' of type String did not match the following type: integer in schema 18a1ffbb-4681-5b00-bd15-2c76aee4b28f"]
JSON::Validator.fully_validate(schema, { "a" => "taco" })
```

Advanced Options
-----------------

```ruby
require "json-schema"

schema = {
  "type"=>"object",
  "required" => ["a"],
  "properties" => {
    "a" => {
      "type" => "integer",
      "default" => 42
    },
    "b" => {
      "type" => "object",
      "properties" => {
        "x" => {
          "type" => "integer"
        }
      }
    }
  }
}

#
# with the `:list` option, a list can be validated against a schema that represents the individual objects
#

# => true
JSON::Validator.validate(schema, [{"a" => 1}, {"a" => 2}, {"a" => 3}], :list => true)
# => false
JSON::Validator.validate(schema, [{"a" => 1}, {"a" => 2}, {"a" => 3}])

#
# with the `:errors_as_objects` option, `#fully_validate` returns errors as hashes instead of strings
#

# => [{:schema=>#<Addressable::URI:0x3ffa69cbeed8 URI:18a1ffbb-4681-5b00-bd15-2c76aee4b28f>, :fragment=>"#/a", :message=>"The property '#/a' of type String did not match the following type: integer in schema 18a1ffbb-4681-5b00-bd15-2c76aee4b28f", :failed_attribute=>"TypeV4"}]
JSON::Validator.fully_validate(schema, { "a" => "taco" }, :errors_as_objects => true)

#
# with the `:strict` option, all properties are condisidered to have `"required": true` and all objects `"additionalProperties": false`
#

# => true
JSON::Validator.validate(schema, { "a" => 1, "b" => { "x" => 2 } }, :strict => true)
# => false
JSON::Validator.validate(schema, { "a" => 1, "b" => { "x" => 2 }, "c" => 3 }, :strict => true)
# => false
JSON::Validator.validate(schema, { "a" => 1 }, :strict => true)

#
# with the `:fragment` option, only a fragment of the schema is used for validation
#

# => true
JSON::Validator.validate(schema, { "x" => 1 }, :fragment => "#/properties/b")
# => false
JSON::Validator.validate(schema, { "x" => 1 })

#
# with the `:validate_schema` option, the schema is validated (against the json schema spec) before the json is validated (against the specified schema)
#

# => true
JSON::Validator.validate(schema, { "a" => 1 }, :validate_schema => true)
# => false
JSON::Validator.validate({ "required" => true }, { "a" => 1 }, :validate_schema => true)

#
# with the `:insert_defaults` option, any undefined values in the json that have a default in the schema are replaced with the default before validation
#

# => true
JSON::Validator.validate(schema, {}, :insert_defaults => true)
# => false
JSON::Validator.validate(schema, {})

#
# with the `:version` option, schemas conforming to older drafts of the json schema spec can be used
#

v2_schema = {
  "type" => "object",
  "properties" => {
    "a" => {
      "type" => "integer"
    }
  }
}

# => false
JSON::Validator.validate(v2_schema, {}, :version => :draft2)
# => true
JSON::Validator.validate(v2_schema, {})

#
# with the `:parse_data` option set to false, the json must be a parsed ruby object (not a json text, a uri or a file path)
#

# => true
JSON::Validator.validate(schema, { "a" => 1 }, :parse_data => false)
# => false
JSON::Validator.validate(schema, '{ "a": 1 }', :parse_data => false)

#
# with the `:json` option, the json must be an unparsed json text (not a hash, a uri or a file path)
#

# => true
JSON::Validator.validate(schema, '{ "a": 1 }', :json => true)
# => "no implicit conversion of Hash into String"
begin
  JSON::Validator.validate(schema, { "a" => 1 }, :json => true)
rescue TypeError => e
  e.message
end

#
# with the `:uri` option, the json must be a uri or file path (not a hash or a json text)
#

File.write("data.json", '{ "a": 1 }')

# => true
JSON::Validator.validate(schema, "data.json", :uri => true)
# => "Can't convert Hash into String."
begin
  JSON::Validator.validate(schema, { "a"  => 1 }, :uri => true)
rescue TypeError => e
  e.message
end

#
# with the `:clear_cache` option set to true, the internal cache of schemas is
# cleared after validation (otherwise schemas are cached for efficiency)
#

File.write("schema.json", v2_schema.to_json)

# => true
JSON::Validator.validate("schema.json", {})

File.write("schema.json", schema.to_json)

# => true
JSON::Validator.validate("schema.json", {}, :clear_cache => true)

# => false
JSON::Validator.validate("schema.json", {})
```

Extending Schemas
-----------------

For this example, we are going to extend the [JSON Schema Draft
3](http://tools.ietf.org/html/draft-zyp-json-schema-03) specification by adding
a 'bitwise-and' property for validation.

```ruby
require "json-schema"

class BitwiseAndAttribute < JSON::Schema::Attribute
  def self.validate(current_schema, data, fragments, processor, validator, options = {})
    if data.is_a?(Integer) && data & current_schema.schema['bitwise-and'].to_i == 0
      message = "The property '#{build_fragment(fragments)}' did not evaluate  to true when bitwise-AND'd with  #{current_schema.schema['bitwise-or']}"
      validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
    end
  end
end

class ExtendedSchema < JSON::Schema::Draft3
  def initialize
    super
    @attributes["bitwise-and"] = BitwiseAndAttribute
    @uri = JSON::Util::URI.parse("http://test.com/test.json")
    @names = ["http://test.com/test.json"]
  end

  JSON::Validator.register_validator(self.new)
end

schema = {
  "$schema" => "http://test.com/test.json",
  "properties" => {
    "a" => {
      "bitwise-and" => 1
    },
    "b" => {
      "type" => "string"
    }
  }
}

data = {
  "a" => 0
}

data = {"a" => 1, "b" => "taco"}
JSON::Validator.validate(schema,data) # => true
data = {"a" => 1, "b" => 5}
JSON::Validator.validate(schema,data) # => false
data = {"a" => 0, "b" => "taco"}
JSON::Validator.validate(schema,data) # => false
```

Custom format validation
------------------------

The JSON schema standard allows custom formats in schema definitions which
should be ignored by validators that do not support them. JSON::Schema allows
registering procs as custom format validators which receive the value to be
checked as parameter and must raise a `JSON::Schema::CustomFormatError` to
indicate a format violation. The error message will be prepended by the property
name, e.g. [The property '#a']()

```ruby
require "json-schema"

format_proc = -> value {
  raise JSON::Schema::CustomFormatError.new("must be 42") unless value == "42"
}

# register the proc for format 'the-answer' for draft4 schema
JSON::Validator.register_format_validator("the-answer", format_proc, ["draft4"])

# omitting the version parameter uses ["draft1", "draft2", "draft3", "draft4"] as default
JSON::Validator.register_format_validator("the-answer", format_proc)

# deregistering the custom validator
# (also ["draft1", "draft2", "draft3", "draft4"] as default version)
JSON::Validator.deregister_format_validator('the-answer', ["draft4"])

# shortcut to restore the default formats for validators (same default as before)
JSON::Validator.restore_default_formats(["draft4"])

# with the validator registered as above, the following results in
# ["The property '#a' must be 42"] as returned errors
schema = {
  "$schema" => "http://json-schema.org/draft-04/schema#",
  "properties" => {
    "a" => {
      "type" => "string",
      "format" => "the-answer",
    }
  }
}
errors = JSON::Validator.fully_validate(schema, {"a" => "23"})
```

Validating a JSON Schema
------------------------

To validate that a JSON Schema conforms to the JSON Schema standard,
you need to validate your schema against the metaschema for the appropriate
JSON Schema Draft. All of the normal validation methods can be used
for this. First retrieve the appropriate metaschema from the internal
cache (using `JSON::Validator.validator_for_name()` or
`JSON::Validator.validator_for_uri()`) and then simply validate your
schema against it.


```ruby
require "json-schema"

schema = {
  "type" => "object",
  "properties" => {
    "a" => {"type" => "integer"}
  }
}

metaschema = JSON::Validator.validator_for_name("draft4").metaschema
# => true
JSON::Validator.validate(metaschema, schema)
```

Controlling Remote Schema Reading
---------------------------------

In some cases, you may wish to prevent the JSON Schema library from making HTTP
calls or reading local files in order to resolve `$ref` schemas. If you fully
control all schemas which should be used by validation, this could be
accomplished by registering all referenced schemas with the validator in
advance:

```ruby
schema = JSON::Schema.new(some_schema_definition, Addressable::URI.parse('http://example.com/my-schema'))
JSON::Validator.add_schema(schema)
```

If more extensive control is necessary, the `JSON::Schema::Reader` instance used
can be configured in a few ways:

```ruby
# Change the default schema reader used
JSON::Validator.schema_reader = JSON::Schema::Reader.new(:accept_uri => true, :accept_file => false)

# For this validation call, use a reader which only accepts URIs from my-website.com
schema_reader = JSON::Schema::Reader.new(
  :accept_uri => proc { |uri| uri.host == 'my-website.com' }
)
JSON::Validator.validate(some_schema, some_object, :schema_reader => schema_reader)
```

The `JSON::Schema::Reader` interface requires only an object which responds to
`read(string)` and returns a `JSON::Schema` instance. See the [API
documentation](http://www.rubydoc.info/github/ruby-json-schema/json-schema/master/JSON/Schema/Reader)
for more information.

JSON Backends
-------------

The JSON Schema library currently supports the `json` and `yajl-ruby` backend
JSON parsers. If either of these libraries are installed, they will be
automatically loaded and used to parse any JSON strings supplied by the user.

If more than one of the supported JSON backends are installed, the `yajl-ruby`
parser is used by default. This can be changed by issuing the following before
validation:

```ruby
JSON::Validator.json_backend = :json
```

Optionally, the JSON Schema library supports using the MultiJSON library for
selecting JSON backends. If the MultiJSON library is installed, it will be
autoloaded.

Notes
-----

The 'format' attribute is only validated for the following values:

- date-time
- date
- time
- ip-address (IPv4 address in draft1, draft2 and draft3)
- ipv4 (IPv4 address in draft4)
- ipv6
- uri

All other 'format' attribute values are simply checked to ensure the instance
value is of the correct datatype (e.g., an instance value is validated to be an
integer or a float in the case of 'utc-millisec').

Additionally, JSON::Validator does not handle any json hyperschema attributes.
