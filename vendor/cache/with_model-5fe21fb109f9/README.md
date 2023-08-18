# [with_model](https://github.com/Casecommons/with_model)

[![Gem Version](https://img.shields.io/gem/v/with_model.svg?style=flat)](https://rubygems.org/gems/with_model)
[![Build Status](https://github.com/Casecommons/with_model/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Casecommons/with_model/actions/workflows/ci.yml)
[![API Documentation](https://img.shields.io/badge/yard-api%20docs-lightgrey.svg)](https://www.rubydoc.info/gems/with_model)

`with_model` dynamically builds an Active Record model (with table) before each
test in a group and destroys it afterwards.

## Development status

`with_model` is actively maintained. It is quite stable, so while updates may
appear infrequent, it is only because none are needed.

## Installation

Install as usual: `gem install with_model` or add `gem 'with_model'` to your
Gemfile. See [`.github/workflows/ci.yml`](./.github/workflows/ci.yml) for
supported (tested) Ruby versions.

### RSpec

Extend `WithModel` into RSpec:

```ruby
require 'with_model'

RSpec.configure do |config|
  config.extend WithModel
end
```

### minitest/spec

Extend `WithModel` into minitest/spec and set the test runner explicitly:

```ruby
require 'with_model'

WithModel.runner = :minitest

class Minitest::Spec
  extend WithModel
end
```

## Usage

After setting up as above, call `with_model` and inside its block pass it a
`table` block and a `model` block.

```ruby
require 'spec_helper'

describe "A blog post" do
  module MyModule; end

  with_model :BlogPost do
    # The table block (and an options hash) is passed to Active Record migration’s `create_table`.
    table do |t|
      t.string :title
      t.timestamps null: false
    end

    # The model block is the Active Record model’s class body.
    model do
      include MyModule
      has_many :comments
      validates_presence_of :title

      def self.some_class_method
        'chunky'
      end

      def some_instance_method
        'bacon'
      end
    end
  end

  # with_model classes can have associations.
  with_model :Comment do
    table do |t|
      t.string :text
      t.belongs_to :blog_post
      t.timestamps null: false
    end

    model do
      belongs_to :blog_post
    end
  end

  it "can be accessed as a constant" do
    expect(BlogPost).to be
  end

  it "has the module" do
    expect(BlogPost.include?(MyModule)).to eq true
  end

  it "has the class method" do
    expect(BlogPost.some_class_method).to eq 'chunky'
  end

  it "has the instance method" do
    expect(BlogPost.new.some_instance_method).to eq 'bacon'
  end

  it "can do all the things a regular model can" do
    record = BlogPost.new
    expect(record).not_to be_valid
    record.title = "foo"
    expect(record).to be_valid
    expect(record.save).to eq true
    expect(record.reload).to eq record
    record.comments.create!(:text => "Lorem ipsum")
    expect(record.comments.count).to eq 1
  end

  # with_model classes can have inheritance.
  class Car < ActiveRecord::Base
    self.abstract_class = true
  end

  with_model :Ford, superclass: Car do
  end

  it "has a specified superclass" do
    expect(Ford < Car).to eq true
  end
end

describe "with_model can be run within RSpec :all hook" do
  with_model :BlogPost, scope: :all do
    table do |t|
      t.string :title
    end
  end

  before :all do
    BlogPost.create # without scope: :all these will fail
  end

  it "has been initialized within before(:all)" do
    expect(BlogPost.count).to eq 1
  end
end

describe "another example group" do
  it "does not have the constant anymore" do
    expect(defined?(BlogPost)).to be_falsy
  end
end

describe "with table options" do
  with_model :WithOptions do
    table :id => false do |t|
      t.string 'foo'
      t.timestamps null: false
    end
  end

  it "respects the additional options" do
    expect(WithOptions.columns.map(&:name)).not_to include("id")
  end
end
```

## Requirements

See the [gemspec metadata](https://rubygems.org/gems/with_model) for dependency
requirements. RSpec and minitest are indirect dependencies, and `with_model`
should support any maintained version of both.

## Thread-safety

- A unique table name is used for tables generated via
  `with_model`/`WithModel::Model.new`. This allows `with_model` (when limited to
  this API) to run concurrently (in processes or threads) with a single database
  schema. While there is a possibility of collision, it is very small.
- A user-supplied table name is used for tables generated via
  `with_table`/`WithModel::Table.new`. This may cause collisions at runtime if
  tests are run concurrently against a single database schema, unless the caller
  takes care to ensure the table names passed as arguments are unique across
  threads/processes.
- Generated models are created in stubbed constants, which are global; no
  guarantee is made to the uniqueness of a constant, and this may be unsafe.
- Generated classes are Active Record subclasses:
  - This library makes no guarantee as to the thread-safety of creating Active
    Record subclasses concurrently.
  - This library makes no guarantee as to the thread-safety of cleaning up
    Active Record/Active Support’s internals which are polluted upon class
    creation.

In general, `with_model` is not guaranteed to be thread-safe, but is, in certain
usages, safe to use concurrently across multiple processes with a single
database schema.

## Versioning

`with_model` uses
[Semantic Versioning 2.0.0](http://semver.org/spec/v2.0.0.html).

## License

Copyright © 2010–2022 [Casebook PBC](https://www.casebook.net). Licensed under
the MIT license, see [LICENSE](/LICENSE) file.
