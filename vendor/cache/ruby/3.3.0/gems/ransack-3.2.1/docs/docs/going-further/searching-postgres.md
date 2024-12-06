---
sidebar_position: 8
title: Postgres searches
---

Searching on Postgres-specific column types.

## Postgres Array searches

See [this issue](https://github.com/activerecord-hackery/ransack/issues/321) for details.

## PostgreSQL JSONB searches

### Using a fixed key

See here for searching on a fixed key in a JSONB column: https://github.com/activerecord-hackery/ransack/wiki/Using-Ransackers#3-search-on-a-fixed-key-in-a-jsonb--hstore-column

### Using the JSONB contains operator

To fully use the power of the JSONB column you may want to filter on any key though:

Install the [ActiveRecordExtended](https://github.com/GeorgeKaraszi/ActiveRecordExtended) gem to add the `contains` arel predicate to your project. It let's you use the [Postgres contains operator @>](https://www.postgresql.org/docs/12/functions-json.html#FUNCTIONS-JSONB-OP-TABLE).

Add a custom predicate in the `config/initializers/ransack.rb` file:
```ruby
Ransack.configure do |config|
  config.add_predicate 'jcont', arel_predicate: 'contains', formatter: proc { |v| JSON.parse(v) }
end
```

Now you can ransack the JSONB columns using the _jcont predicate. For example the Person model has a `data` JSONB column, find entries where the column contains the {"group": "experts"} key-value pair:

    Person.ransack(data_jcont: '{"group": "experts"}').result.to_sql

    SELECT "persons".* FROM "persons" WHERE "persons"."data" @> '"{\"group\": \"experts\"}"'

If you have a GIN index on that column, the database will quickly be able to find that result.

### Treating the column as a string

Warning: This method converts the column to a string and matches the given string to the result. This will be slow on large data_sets and does not make good use of the JSONB capabilities of Postgres, such as indexes.

```ruby
class Contact < ApplicationRecord
  ransacker :within_json do |parent|
    Arel.sql("table.jsonb_data::text")
  end
end

Contact.all.ransack("within_json_cont" => "my")
```

Will generate

`SELECT "contacts".* FROM "contacts" WHERE contacts.json_data ILIKE '%my%'`

Note that this search treats the entire JSON as string, including parens, etc. i.e. you can search for e.g.: `Contact.all.ransack("within_json_cont" => '{"key": "value"}')`
