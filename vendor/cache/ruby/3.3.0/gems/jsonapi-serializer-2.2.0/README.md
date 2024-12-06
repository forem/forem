# JSON:API Serialization Library

## :warning: :construction: [At the moment, contributions are welcome only for v3](https://github.com/jsonapi-serializer/jsonapi-serializer/pull/141)! :construction: :warning:

A fast [JSON:API](https://jsonapi.org/) serializer for Ruby Objects.

Previously this project was called **fast_jsonapi**, we forked the project
and renamed it to **jsonapi/serializer** in order to keep it alive.

We would like to thank the Netflix team for the initial work and to all our
contributors and users for the continuous support!

# Performance Comparison

We compare serialization times with `ActiveModelSerializer` and alternative
implementations as part of performance tests available at
[jsonapi-serializer/comparisons](https://github.com/jsonapi-serializer/comparisons).

We want to ensure that with every
change on this library, serialization time stays significantly faster than
the performance provided by the alternatives. Please read the performance
article in the `docs` folder for any questions related to methodology.

# Table of Contents

* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
  * [Rails Generator](#rails-generator)
  * [Model Definition](#model-definition)
  * [Serializer Definition](#serializer-definition)
  * [Object Serialization](#object-serialization)
  * [Compound Document](#compound-document)
  * [Key Transforms](#key-transforms)
  * [Collection Serialization](#collection-serialization)
  * [Caching](#caching)
  * [Params](#params)
  * [Conditional Attributes](#conditional-attributes)
  * [Conditional Relationships](#conditional-relationships)
  * [Specifying a Relationship Serializer](#specifying-a-relationship-serializer)
  * [Sparse Fieldsets](#sparse-fieldsets)
  * [Using helper methods](#using-helper-methods)
* [Performance Instrumentation](#performance-instrumentation)
* [Deserialization](#deserialization)
* [Migrating from Netflix/fast_jsonapi](#migrating-from-netflixfast_jsonapi)
* [Contributing](#contributing)


## Features

* Declaration syntax similar to Active Model Serializer
* Support for `belongs_to`, `has_many` and `has_one`
* Support for compound documents (included)
* Optimized serialization of compound documents
* Caching

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi-serializer'
```

Execute:

```bash
$ bundle install
```

## Usage

### Rails Generator
You can use the bundled generator if you are using the library inside of
a Rails project:

    rails g serializer Movie name year

This will create a new serializer in `app/serializers/movie_serializer.rb`

### Model Definition

```ruby
class Movie
  attr_accessor :id, :name, :year, :actor_ids, :owner_id, :movie_type_id
end
```

### Serializer Definition

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  set_type :movie  # optional
  set_id :owner_id # optional
  attributes :name, :year
  has_many :actors
  belongs_to :owner, record_type: :user
  belongs_to :movie_type
end
```

### Sample Object

```ruby
movie = Movie.new
movie.id = 232
movie.name = 'test movie'
movie.actor_ids = [1, 2, 3]
movie.owner_id = 3
movie.movie_type_id = 1
movie

movies =
  2.times.map do |i|
    m = Movie.new
    m.id = i + 1
    m.name = "test movie #{i}"
    m.actor_ids = [1, 2, 3]
    m.owner_id = 3
    m.movie_type_id = 1
    m
  end
```

### Object Serialization

#### Return a hash
```ruby
hash = MovieSerializer.new(movie).serializable_hash
```

#### Return Serialized JSON
```ruby
json_string = MovieSerializer.new(movie).serializable_hash.to_json
```

#### Serialized Output

```json
{
  "data": {
    "id": "3",
    "type": "movie",
    "attributes": {
      "name": "test movie",
      "year": null
    },
    "relationships": {
      "actors": {
        "data": [
          {
            "id": "1",
            "type": "actor"
          },
          {
            "id": "2",
            "type": "actor"
          }
        ]
      },
      "owner": {
        "data": {
          "id": "3",
          "type": "user"
        }
      }
    }
  }
}

```

#### The Optionality of `set_type`
By default fast_jsonapi will try to figure the type based on the name of the serializer class. For example `class MovieSerializer` will automatically have a type of `:movie`. If your serializer class name does not follow this format, you have to manually state the `set_type` at the serializer.

### Key Transforms
By default fast_jsonapi underscores the key names. It supports the same key transforms that are supported by AMS. Here is the syntax of specifying a key transform

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  # Available options :camel, :camel_lower, :dash, :underscore(default)
  set_key_transform :camel
end
```
Here are examples of how these options transform the keys

```ruby
set_key_transform :camel # "some_key" => "SomeKey"
set_key_transform :camel_lower # "some_key" => "someKey"
set_key_transform :dash # "some_key" => "some-key"
set_key_transform :underscore # "some_key" => "some_key"
```

### Attributes
Attributes are defined using the `attributes` method.  This method is also aliased as `attribute`, which is useful when defining a single attribute.

By default, attributes are read directly from the model property of the same name.  In this example, `name` is expected to be a property of the object being serialized:

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  attribute :name
end
```

Custom attributes that must be serialized but do not exist on the model can be declared using Ruby block syntax:

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  attributes :name, :year

  attribute :name_with_year do |object|
    "#{object.name} (#{object.year})"
  end
end
```

The block syntax can also be used to override the property on the object:

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  attribute :name do |object|
    "#{object.name} Part 2"
  end
end
```

Attributes can also use a different name by passing the original method or accessor with a proc shortcut:

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  attributes :name

  attribute :released_in_year, &:year
end
```

### Links Per Object
Links are defined using the `link` method. By default, links are read directly from the model property of the same name. In this example, `public_url` is expected to be a property of the object being serialized.

You can configure the method to use on the object for example a link with key `self` will get set to the value returned by a method called `url` on the movie object.

You can also use a block to define a url as shown in `custom_url`. You can access params in these blocks as well as shown in `personalized_url`

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  link :public_url

  link :self, :url

  link :custom_url do |object|
    "https://movies.com/#{object.name}-(#{object.year})"
  end

  link :personalized_url do |object, params|
    "https://movies.com/#{object.name}-#{params[:user].reference_code}"
  end
end
```

#### Links on a Relationship

You can specify [relationship links](https://jsonapi.org/format/#document-resource-object-relationships) by using the `links:` option on the serializer. Relationship links in JSON API are useful if you want to load a parent document and then load associated documents later due to size constraints (see [related resource links](https://jsonapi.org/format/#document-resource-object-related-resource-links))

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  has_many :actors, links: {
    self: :url,
    related: -> (object) {
      "https://movies.com/#{object.id}/actors"
    }
  }
end
```

Relationship links can also be configured to be defined as a method on the object.

```ruby
  has_many :actors, links: :actor_relationship_links
```

This will create a `self` reference for the relationship, and a `related` link for loading the actors relationship later. NB: This will not automatically disable loading the data in the relationship, you'll need to do that using the `lazy_load_data` option:

```ruby
  has_many :actors, lazy_load_data: true, links: {
    self: :url,
    related: -> (object) {
      "https://movies.com/#{object.id}/actors"
    }
  }
```

### Meta Per Resource

For every resource in the collection, you can include a meta object containing non-standard meta-information about a resource that can not be represented as an attribute or relationship.


```ruby
class MovieSerializer
  include JSONAPI::Serializer

  meta do |movie|
    {
      years_since_release: Date.current.year - movie.year
    }
  end
end
```

#### Meta on a Relationship

You can specify [relationship meta](https://jsonapi.org/format/#document-resource-object-relationships) by using the `meta:` option on the serializer. Relationship meta in JSON API is useful if you wish to provide non-standard meta-information about the relationship.

Meta can be defined either by passing a static hash or by using Proc to the `meta` key. In the latter case, the record and any params passed to the serializer are available inside the Proc as the first and second parameters, respectively.


```ruby
class MovieSerializer
  include JSONAPI::Serializer

  has_many :actors, meta: Proc.new do |movie_record, params|
    { count: movie_record.actors.length }
  end
end
```

### Compound Document

Support for top-level and nested included associations through `options[:include]`.

```ruby
options = {}
options[:meta] = { total: 2 }
options[:links] = {
  self: '...',
  next: '...',
  prev: '...'
}
options[:include] = [:actors, :'actors.agency', :'actors.agency.state']
MovieSerializer.new(movies, options).serializable_hash.to_json
```

### Collection Serialization

```ruby
options[:meta] = { total: 2 }
options[:links] = {
  self: '...',
  next: '...',
  prev: '...'
}
hash = MovieSerializer.new(movies, options).serializable_hash
json_string = MovieSerializer.new(movies, options).serializable_hash.to_json
```

#### Control Over Collection Serialization

You can use `is_collection` option to have better control over collection serialization.

If this option is not provided or `nil` autodetect logic is used to try understand
if provided resource is a single object or collection.

Autodetect logic is compatible with most DB toolkits (ActiveRecord, Sequel, etc.) but
**cannot** guarantee that single vs collection will be always detected properly.

```ruby
options[:is_collection]
```

was introduced to be able to have precise control this behavior

- `nil` or not provided: will try to autodetect single vs collection (please, see notes above)
- `true` will always treat input resource as *collection*
- `false` will always treat input resource as *single object*

### Caching

To enable caching, use `cache_options store: <cache_store>`:

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  # use rails cache with a separate namespace and fixed expiry
  cache_options store: Rails.cache, namespace: 'jsonapi-serializer', expires_in: 1.hour
end
```

`store` is required can be anything that implements a
`#fetch(record, **options, &block)` method:

- `record` is the record that is currently serialized
- `options` is everything that was passed to `cache_options` except `store`, so it can be everyhing the cache store supports
- `&block` should be executed to fetch new data if cache is empty

So for the example above it will call the cache instance like this:

```ruby
Rails.cache.fetch(record, namespace: 'jsonapi-serializer', expires_in: 1.hour) { ... }
```

#### Caching and Sparse Fieldsets

If caching is enabled and fields are provided to the serializer, the fieldset will be appended to the cache key's namespace.

For example, given the following serializer definition and instance:
```ruby
class ActorSerializer
  include JSONAPI::Serializer

  attributes :first_name, :last_name

  cache_options store: Rails.cache, namespace: 'jsonapi-serializer', expires_in: 1.hour
end

serializer = ActorSerializer.new(actor, { fields: { actor: [:first_name] } })
```

The following cache namespace will be generated: `'jsonapi-serializer-fieldset:first_name'`.

### Params

In some cases, attribute values might require more information than what is
available on the record, for example, access privileges or other information
related to a current authenticated user. The `options[:params]` value covers these
cases by allowing you to pass in a hash of additional parameters necessary for
your use case.

Leveraging the new params is easy, when you define a custom id, attribute or
relationship with a block you opt-in to using params by adding it as a block
parameter.

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  set_id do |movie, params|
    # in here, params is a hash containing the `:admin` key
    params[:admin] ? movie.owner_id : "movie-#{movie.id}"
  end

  attributes :name, :year
  attribute :can_view_early do |movie, params|
    # in here, params is a hash containing the `:current_user` key
    params[:current_user].is_employee? ? true : false
  end

  belongs_to :primary_agent do |movie, params|
    # in here, params is a hash containing the `:current_user` key
    params[:current_user]
  end
end

# ...
current_user = User.find(cookies[:current_user_id])
serializer = MovieSerializer.new(movie, {params: {current_user: current_user}})
serializer.serializable_hash
```

Custom attributes and relationships that only receive the resource are still possible by defining
the block to only receive one argument.

### Conditional Attributes

Conditional attributes can be defined by passing a Proc to the `if` key on the `attribute` method. Return `true` if the attribute should be serialized, and `false` if not. The record and any params passed to the serializer are available inside the Proc as the first and second parameters, respectively.

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  attributes :name, :year
  attribute :release_year, if: Proc.new { |record|
    # Release year will only be serialized if it's greater than 1990
    record.release_year > 1990
  }

  attribute :director, if: Proc.new { |record, params|
    # The director will be serialized only if the :admin key of params is true
    params && params[:admin] == true
  }

  # Custom attribute `name_year` will only be serialized if both `name` and `year` fields are present
  attribute :name_year, if: Proc.new { |record|
    record.name.present? && record.year.present?
  } do |object|
    "#{object.name} - #{object.year}"
  end
end

# ...
current_user = User.find(cookies[:current_user_id])
serializer = MovieSerializer.new(movie, { params: { admin: current_user.admin? }})
serializer.serializable_hash
```

### Conditional Relationships

Conditional relationships can be defined by passing a Proc to the `if` key. Return `true` if the relationship should be serialized, and `false` if not. The record and any params passed to the serializer are available inside the Proc as the first and second parameters, respectively.

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  # Actors will only be serialized if the record has any associated actors
  has_many :actors, if: Proc.new { |record| record.actors.any? }

  # Owner will only be serialized if the :admin key of params is true
  belongs_to :owner, if: Proc.new { |record, params| params && params[:admin] == true }
end

# ...
current_user = User.find(cookies[:current_user_id])
serializer = MovieSerializer.new(movie, { params: { admin: current_user.admin? }})
serializer.serializable_hash
```

### Specifying a Relationship Serializer

In many cases, the relationship can automatically detect the serializer to use.

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  # resolves to StudioSerializer
  belongs_to :studio
  # resolves to ActorSerializer
  has_many :actors
end
```

At other times, such as when a property name differs from the class name, you may need to explicitly state the serializer to use.  You can do so by specifying a different symbol or the serializer class itself (which is the recommended usage):

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  # resolves to MovieStudioSerializer
  belongs_to :studio, serializer: :movie_studio
  # resolves to PerformerSerializer
  has_many :actors, serializer: PerformerSerializer
end
```

For more advanced cases, such as polymorphic relationships and Single Table Inheritance, you may need even greater control to select the serializer based on the specific object or some specified serialization parameters. You can do by defining the serializer as a `Proc`:

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  has_many :actors, serializer: Proc.new do |record, params|
    if record.comedian?
      ComedianSerializer
    elsif params[:use_drama_serializer]
      DramaSerializer
    else
      ActorSerializer
    end
  end
end
```

### Sparse Fieldsets

Attributes and relationships can be selectively returned per record type by using the `fields` option.

```ruby
class MovieSerializer
  include JSONAPI::Serializer

  attributes :name, :year
end

serializer = MovieSerializer.new(movie, { fields: { movie: [:name] } })
serializer.serializable_hash
```

### Using helper methods

You can mix-in code from another ruby module into your serializer class to reuse functions across your app.

Since a serializer is evaluated in a the context of a `class` rather than an `instance` of a class, you need to make sure that your methods act as `class` methods when mixed in.


##### Using ActiveSupport::Concern

``` ruby

module AvatarHelper
  extend ActiveSupport::Concern

  class_methods do
    def avatar_url(user)
      user.image.url
    end
  end
end

class UserSerializer
  include JSONAPI::Serializer

  include AvatarHelper # mixes in your helper method as class method

  set_type :user

  attributes :name, :email

  attribute :avatar do |user|
    avatar_url(user)
  end
end

```

##### Using Plain Old Ruby

``` ruby
module AvatarHelper
  def avatar_url(user)
    user.image.url
  end
end

class UserSerializer
  include JSONAPI::Serializer

  extend AvatarHelper # mixes in your helper method as class method

  set_type :user

  attributes :name, :email

  attribute :avatar do |user|
    avatar_url(user)
  end
end

```

### Customizable Options

Option | Purpose | Example
------------ | ------------- | -------------
set_type | Type name of Object | `set_type :movie`
key | Key of Object | `belongs_to :owner, key: :user`
set_id | ID of Object | `set_id :owner_id` or `set_id { \|record, params\| params[:admin] ? record.id : "#{record.name.downcase}-#{record.id}" }`
cache_options | Hash with store to enable caching and optional further cache options | `cache_options store: ActiveSupport::Cache::MemoryStore.new, expires_in: 5.minutes`
id_method_name | Set custom method name to get ID of an object (If block is provided for the relationship, `id_method_name` is invoked on the return value of the block instead of the resource object) | `has_many :locations, id_method_name: :place_ids`
object_method_name | Set custom method name to get related objects | `has_many :locations, object_method_name: :places`
record_type | Set custom Object Type for a relationship | `belongs_to :owner, record_type: :user`
serializer | Set custom Serializer for a relationship | `has_many :actors, serializer: :custom_actor`, `has_many :actors, serializer: MyApp::Api::V1::ActorSerializer`, or `has_many :actors, serializer -> (object, params) { (return a serializer class) }`
polymorphic | Allows different record types for a polymorphic association | `has_many :targets, polymorphic: true`
polymorphic | Sets custom record types for each object class in a polymorphic association | `has_many :targets, polymorphic: { Person => :person, Group => :group }`

### Performance Instrumentation

Performance instrumentation is available by using the
`active_support/notifications`.

To enable it, include the module in your serializer class:

```ruby
require 'jsonapi/serializer'
require 'jsonapi/serializer/instrumentation'

class MovieSerializer
  include JSONAPI::Serializer
  include JSONAPI::Serializer::Instrumentation

  # ...
end
```

[Skylight](https://www.skylight.io/) integration is also available and
supported by us, follow the Skylight documentation to enable it.

### Running Tests
The project has and requires unit tests, functional tests and performance
tests. To run tests use the following command:

```bash
rspec
```

## Deserialization
We currently do not support deserialization, but we recommend to use any of the next gems:

### [JSONAPI.rb](https://github.com/stas/jsonapi.rb)

This gem provides the next features alongside deserialization:
- Collection meta
- Error handling
- Includes and sparse fields
- Filtering and sorting
- Pagination

## Migrating from Netflix/fast_jsonapi

If you come from [Netflix/fast_jsonapi](https://github.com/Netflix/fast_jsonapi), here is the instructions to switch.

### Modify your Gemfile

```diff
- gem 'fast_jsonapi'
+ gem 'jsonapi-serializer'
```

### Replace all constant references

```diff
class MovieSerializer
- include FastJsonapi::ObjectSerializer
+ include JSONAPI::Serializer
end
```

### Replace removed methods

```diff
- json_string = MovieSerializer.new(movie).serialized_json
+ json_string = MovieSerializer.new(movie).serializable_hash.to_json
```

### Replace require references

```diff
- require 'fast_jsonapi'
+ require 'jsonapi/serializer'
```

### Update your cache options

See [docs](https://github.com/jsonapi-serializer/jsonapi-serializer#caching).

```diff
- cache_options enabled: true, cache_length: 12.hours
+ cache_options store: Rails.cache, namespace: 'jsonapi-serializer', expires_in: 1.hour
```

## Contributing

Please follow the instructions we provide as part of the issue and
pull request creation processes.

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](https://contributor-covenant.org) code of conduct.
