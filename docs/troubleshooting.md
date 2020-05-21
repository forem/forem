---
title: Troubleshooting
---

## Tests

### Connection timeout

While running test cases, if you get an error message
`postgresql connection timeout`, please re-run the tests by increasing the
statement timeout, for example:

```shell
STATEMENT_TIMEOUT=10000 bundle exec rspec
```

## PostgreSQL

### How do I fix the Error `role "ec2-user" does not exist` on an AWS instance?

After installing and configuring PostgreSQL on an AWS EC2 (or AWS Cloud9)
instance and running `bin/setup`, this error could occur.

To fix it, run the following two commands in a terminal (assuming your
PostgreSQL user is named **postgres**):

```
sudo -u postgres createuser -s ec2-user
sudo -u postgres createdb ec2-user
```

The first command creates the user **ec2-user** and the second one creates the
database for this user because every user needs its database. Even if the first
command fails, run the second command to create the missing database.

## Elasticsearch

### Index read-only error

If you encounter an error similar to the following:

```shell
{"error":{"root_cause":[{"type":"cluster_block_exception","reason":"index [tags_development] blocked by: [FORBIDDEN/12/index read-only / allow delete (api)];"}],"type":"cluster_block_exception","reason":"index [tags_development] blocked by: [FORBIDDEN/12/index read-only / allow delete (api)];"},"status":403}
```

it means that Elasticsearch went into read only mode because its disk allocator
noticed how the disk drive is nearly full:

> Elasticsearch enforces a read-only index block
> (`index.blocks.read_only_allow_delete`) on every index that has one or more
> shards allocated on the node that has at least one disk exceeding the flood
> stage.

This is an indication that you might not have enough space for ES to work
correctly.

If you want to disable the threshold check on your local machine you can open a
Rails console (with `rails console`) and issue the following command:

```ruby
Search::Client.cluster.put_settings(body: {
  persistent: {
    "cluster.routing.allocation.disk.threshold_enabled" => false,
  }
})
```

To disable the "read only" mode to allow operations on the Elasticsearch indexes
you can issue the following command, similary in the Rails console:

```ruby
Search::Client.indices.get(index: "*").keys.each do |index_name|
  Search::Client.indices.put_settings(
    index: index_name,
    body: { "index.blocks.read_only_allow_delete" => nil }
  )
end
```

If instead you want to tune the Elasticsearch disk allocator's settings, please
refer to
[Disk-based shard allocation](https://www.elastic.co/guide/en/elasticsearch/reference/current/disk-allocator.html#disk-allocator).

## CORS

If you are experiencing CORS issues locally or need to display more information
about the CORS headers, add the following variable to your `application.yml`:

```yml
DEBUG_CORS: true
```
