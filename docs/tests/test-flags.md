---
title: Test Flags
---

# Test Flags

When creating tests using Rspec we have the ability to add flags to those tests
that will signal to Rspec to run certain commands before, after, or around the
test example.

Some flags that we use are:

- `js: true`
- `elasticsearch: reset`
- `elasticsearch: <search class name>`
- `throttle: true`
- `type: <test type>`

### Elasticsearch Flags

Two Elasticsearch flags that can be used when dealing with specs that will be
hitting Elasticsearch. When running a spec that is going to interact with
Elasticsearch, you want Elasticsearch to be clean like your database. Since we
don't have a "database cleaner" for Elasticsearch, we have to do it manually.
There are two ways to do this:

1. `elasticsearch: reset` - This will trigger a complete tear down and rebuild
   of Elasticsearch via a block. This takes time so it's not something you
   want to be doing unless you absolutely have to.

```ruby
  config.around(:each, elasticsearch_reset: true) do |example|
    Search::Cluster.recreate_indexes
    example.run
    Search::Cluster.recreate_indexes
  end
```

2. `elasticsearch: <search class name>` - This will clear the data for the given
   search class index. For example, if you passed "User" as your search class
   name it would clear out the user index data using code from this block.

```ruby
  config.around(:each, :elasticsearch) do |ex|
    klasses = Array.wrap(ex.metadata[:elasticsearch]).map do |search_class|
      Search.const_get(search_class)
    end
    klasses.each { |klass| clear_elasticsearch_data(klass) }
    ex.run
  end
```

**NOTE** Any specs that use the `js: true` flag might be hitting Elasticsearch.
You may want to consider clearing out Elasticsearch data for those specs even if
you don't intend on working with Elasticsearch directly to ensure that you have
a clean page load with no unexpected data.
