---
sidebar_position: 6
title: Ransackers
---

## Add custom search functions

The main premise behind Ransack is to provide access to **Arel predicate methods**. Ransack provides special methods, called _ransackers_, for creating additional search functions via Arel.

A `ransacker` method can **return any Arel node that allows the usual predicate methods**. Custom `ransacker`s are an expert feature, and require a thorough understanding of Arel.

## Arel

Here are some resources for more information about Arel:

* [Using Arel to Compose SQL Queries](https://robots.thoughtbot.com/using-arel-to-compose-sql-queries)
* [The definitive guide to Arel, the SQL manager for Ruby](http://jpospisil.com/2014/06/16/the-definitive-guide-to-arel-the-sql-manager-for-ruby.html)
* [Creating Advanced Active Record DB Queries with Arel](https://www.cloudbees.com/blog/creating-advanced-active-record-db-queries-arel)

Ransacker methods enable search customization and are placed in the model. Arguments may be passed to a ransacker method via `ransacker_args` (see Example #6 below).

Ransackers, like scopes, are not a cure-all. Many use cases can be better solved with a standard Ransack search on a dedicated database search field, which is faster, index-able, and scales better than converting/ransacking data on the fly.

## Example Ransackers

### Search on field

_Search on the `name` field reversed:_
```ruby
# in the model:
ransacker :reversed_name, formatter: proc { |v| v.reverse } do |parent|
  parent.table[:name]
end
```
### Search using Datetime

_Convert a user `string` input and a database `datetime` field to the same `date` format to find all records with a `datetime` field (`created_at` in this example) equal to that date :_

```ruby
# in the model:
ransacker :created_at do
  Arel.sql('date(created_at)')
end
```
```erb
in the view:
<%= f.search_field(
  :created_at_date_equals, placeholder: t(:date_format)
  ) %>
...
<%= sort_link(@search, :created_at, default_order: :desc) %>
```

```ruby
# config/initializers/ransack.rb
Ransack.configure do |config|
  config.add_predicate 'date_equals',
    arel_predicate: 'eq',
    formatter: proc { |v| v.to_date },
    validator: proc { |v| v.present? },
    type: :string
end
```

#### 2.1
It seems to be enough to change the model only, but don't forget to define the type that will returned as well.

```ruby
# in the model:
ransacker :created_at, type: :date do
  Arel.sql('date(created_at)')
end
```

#### 2.2. Postgresql with time zones

If you're using different time zones for Rails and Postgresql you should expect to have some problems using the above solution.
Example:
- Rails at GMT -03:00
- Postgresql at GMT -00:00 (UTC)

A timestamp like `2019-07-18 01:21:29.826484` will be truncated to `2019-07-18`.
But for your Rails application `2019-07-18 01:21:29.826484` is `2019-07-17 22:21:29.826484` at your time zone (GMT -03:00). So it should be truncated to `2019-07-17` instead.


So, you should convert the timestamp to your current Rails time zone before extracting the date.

```ruby
# in the model:
ransacker :created_at, type: :date do
  Arel.sql("date(created_at at time zone 'UTC' at time zone '#{Time.zone.name}')")
end
```

Note that `Time.zone.name` should return a time zone string suitable for Postgresql.

### Postgres columns

_Search on a fixed key in a jsonb / hstore column:_

In this example, we are searching a table with a column called `properties` for records containing a key called `link_type`.

For anything up to and including Rails 4.1, add this to your model
```ruby
ransacker :link_type do |parent|    
  Arel::Nodes::InfixOperation.new('->>', parent.table[:properties], 'link_type')
end
```
When using Rails 4.2+ (Arel 6.0+), wrap the value in a `build_quoted` call
```ruby
ransacker :link_type do |parent|    
  Arel::Nodes::InfixOperation.new('->>', parent.table[:properties], Arel::Nodes.build_quoted('link_type'))
end
```
In the view, with a search on `link_type_eq` using a collection select (for example with options like 'twitter', 'facebook', etc.), if the user selects 'twitter', Ransack will run a query like:
```
SELECT * FROM "foos" WHERE "foos"."properties" ->> 'link_type' = 'twitter';
```

To use the JSONB contains operator @> see here: [[PostgreSQL JSONB searches]].

### Type conversions

_Convert an `integer` database field to a `string` in order to be able to use a `cont` predicate (instead of the usual `eq` which works out of the box with integers) to find all records where an integer field (`id` in this example) **contains** an input string:_

Simple version, using PostgreSQL:
```ruby
# in the model:
ransacker :id do
  Arel.sql("to_char(id, '9999999')")
end
```
and the same, using MySQL:
```ruby
ransacker :id do
  Arel.sql("CONVERT(#{table_name}.id, CHAR(8))")
end
```
A more complete version (using PostgreSQL) that adds the table name to avoid ambiguity and strips spaces from the input:
```ruby
ransacker :id do
  Arel.sql(
    "regexp_replace(
      to_char(\"#{table_name}\".\"id\", '9999999'), ' ', '', 'g')"
  )
end
```
In the view, for all 3 versions:
```erb
<%= f.search_field :id_cont, placeholder: 'Id' %>
...
<%= sort_link(@search, :id) %>
```

### Concatenated fields

_Search on a concatenated full name from `first_name` and `last_name` (several examples):_
```ruby
# in the model:
ransacker :full_name do |parent|
  Arel::Nodes::InfixOperation.new('||',
    parent.table[:first_name], parent.table[:last_name])
end

# or, to insert a space between `first_name` and `last_name`:
ransacker :full_name do |parent|
  Arel::Nodes::InfixOperation.new('||',
    Arel::Nodes::InfixOperation.new('||',
      parent.table[:first_name], ' '
    ),
    parent.table[:last_name]
  )
end
# Caveat: with Arel >= 6 the separator ' ' string in the
# preceding example needs to be quoted as follows:
ransacker :full_name do |parent|
  Arel::Nodes::InfixOperation.new('||',
    Arel::Nodes::InfixOperation.new('||',
      parent.table[:first_name], Arel::Nodes.build_quoted(' ')
    ),
    parent.table[:last_name]
  )
end

# works also in mariadb
ransacker :full_name do |parent|
  Arel::Nodes::NamedFunction.new('concat_ws',
    [Arel::Nodes::SqlLiteral.new("' '"), parent.table[:first_name], parent.table[:last_name]])
end

# case insensitive lookup
ransacker :full_name, formatter: proc { |v| v.mb_chars.downcase.to_s } do |parent|
  Arel::Nodes::NamedFunction.new('LOWER',
    [Arel::Nodes::NamedFunction.new('concat_ws',
      [Arel::Nodes::SqlLiteral.new("' '"), parent.table[:first_name], parent.table[:last_name]])])
end
```

### Passing arguments

_Passing arguments to a ransacker:_
Arguments may be passed to a ransacker method via `ransacker_args`:
```ruby

class Person
  ransacker :author_max_title_of_article_where_body_length_between,
  args: [:parent, :ransacker_args] do |parent, args|
    min, max = args
    query = <<-SQL
      (SELECT MAX(articles.title)
         FROM articles
        WHERE articles.person_id = people.id
          AND CHAR_LENGTH(articles.body) BETWEEN #{min.to_i} AND #{max.to_i}
        GROUP BY articles.person_id
      )
    SQL
    Arel.sql(query)
  end
end

# Usage
Person.ransack(
  conditions: [{
    attributes: {
      '0' => {
        name: 'author_max_title_of_article_where_body_length_between',
        ransacker_args: [10, 100]
      }
    },
    predicate_name: 'cont',
    values: ['Ransackers can take arguments']
  }]
)

=> SELECT "people".* FROM "people" WHERE (
     (SELECT MAX(articles.title)
        FROM articles
       WHERE articles.person_id = people.id
         AND CHAR_LENGTH(articles.body) BETWEEN 10 AND 100
       GROUP BY articles.person_id
     )
   LIKE '%Ransackers can take arguments%')
   ORDER BY "people"."id" DESC
```

### Dropdowns

_Adding the attribute values associated with a column name to a searchable attribute in a dropdown options (instead of a traditional column name coming from a table). This is useful if using an associated table which is acting as a join table between a parent table and domain table. This will cache the data as the selections:_

```ruby
# in the model:
Model.pluck(:name).each do |ground|
  ransacker ground.to_sym do |parent|
    Arel::Nodes::InfixOperation.new('AND',
      Arel::Nodes::InfixOperation.new('=', parent.table[:gor_name], ground),
      parent.table[:status]
    )
  end
end

# This will not include the column names in the dropdown
def self.ransackable_attributes(auth_object = nil)
  %w() + _ransackers.keys
end
```

### Testing for existence

_Testing for the existence of a row in another table via a join:_

```ruby
# in the model:
ransacker :price_exists do |parent|
  # SQL syntax for PostgreSQL -- others may differ
  # This returns boolean true or false
  Arel.sql("(select exists (select 1 from prices where prices.book_id = books.id))")
end
```

In the view
```haml
  %td= f.select :price_exists_true, [["Any", 2], ["No", 0], ["Yes", 1]]
```

### Associations

_Performing a query on an association with a differing class name:_

Say we have a model "SalesAccount", which represents a relationship between two users,
one being designated as a "sales_rep". We want to query SalesAccounts by
the name of the sales_rep:

```ruby
# in the model:
class SalesAccount < ActiveRecord::Base
  belongs_to :user
  belongs_to :sales_rep, class_name: :User

# in the controller:
  # The line below would lead to errors thrown later if not for the
  # "joins(:sales_reps)".
  @q = SalesAccount.includes(:user).joins(:sales_rep).ransack(params[:q])
  @sales_accounts = @q.result(distinct: true)
```

In the view:
```erb
<%= f.search_field :sales_rep_name_start %>
```

### Search on translations

_Search for a translated value in a jsonb column:_

_Note: There is also a gem, [Mobility Ransack](https://github.com/shioyama/mobility-ransack), which allows you to search on translated attributes independent of their storage backend._

This will work with any `jsonb` data type. In this case I have a column translated with [Mobility](https://github.com/shioyama/mobility) called `name` with the value `{'en': "Hello", 'es': "Hola"}`.

```ruby
ransacker :name do |parent|    
  Arel::Nodes::InfixOperation.new('->>', parent.table[:name], Arel::Nodes.build_quoted(Mobility.locale))
end
```

_If using Rails 4.1 or under, remove the `build_quoted` call._

You can then search for `name_eq` or `name_cont` and it will do the proper SQL.

***

Please feel free to contribute further code examples!
