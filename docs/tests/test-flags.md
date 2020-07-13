---
title: Test Flags
---

# Test Flags

When creating tests using Rspec we have the ability to add flags to those tests
that will signal to Rspec to run certain commands before, after, or around the
test example.

Some flags that we use are:

- `js: true`
- `elasticsearch_reset: true`
- `elasticsearch: <search class name>`
- `stub_elasticsearch: true`
- `throttle: true`
- `type: <test type>`

### Elasticsearch Flags

Two Elasticsearch flags that can be used when dealing with specs that will be
hitting Elasticsearch. When running a spec that is going to interact with
Elasticsearch, you want Elasticsearch to be clean like your database. Since we
don't have a "database cleaner" for Elasticsearch, we have to do it manually.
There are two ways to do this:

1. `elasticsearch: reset` - This will trigger a complete tear down and rebuild
   of Elasticsearch via a block. This takes time so it's not something you want
   to be doing unless you absolutely have to.

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

### `js: true` Flag

`js: true` indicates that we want the JavaScript on the page to be executed when
the page is rendered, and a headless chrome instance will be initialized to do
so (instead of the default
[rack_test](https://github.com/teamcapybara/capybara#racktest) driver). One side
effect of running our JavaScript in our specs is that a lot of pages will hit
Elasticsearch. Since we don't clean out Elasticsearch between every single spec
(because it is very costly) this can lead to unexpected data being loaded for a
spec. To prevent this from happening, we can use the `:stub_elasticsearch` flag.
The `:stub_elasticsearch` flag will stub all index and search requests made to
Elasticsearch and return an empty response. This will ensure that no unwanted
data shows up on your spec's page.

If you are debugging a `js: true` spec and want to see the browser, you can set
`HEADLESS=false` before running a spec:

```shell
HEADLESS=false bundle exec rspec spec/app/system
```
