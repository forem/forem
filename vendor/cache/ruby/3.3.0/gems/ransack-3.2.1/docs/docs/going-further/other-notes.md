---
sidebar_position: 8
title: Other notes
---

### Ransack Aliases

You can customize the attribute names for your Ransack searches by using a
`ransack_alias`. This is particularly useful for long attribute names that are
necessary when querying associations or multiple columns.

```ruby
class Post < ActiveRecord::Base
  belongs_to :author

  # Abbreviate :author_first_name_or_author_last_name to :author
  ransack_alias :author, :author_first_name_or_author_last_name
end
```

Now, rather than using `:author_first_name_or_author_last_name_cont` in your
form, you can simply use `:author_cont`. This serves to produce more expressive
query parameters in your URLs.

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :author_cont %>
  <%= f.search_field :author_cont %>
<% end %>
```

You can also use `ransack_alias` for sorting.

```ruby
class Post < ActiveRecord::Base
  belongs_to :author

  # Abbreviate :author_first_name to :author
  ransack_alias :author, :author_first_name
end
```

Now, you can use `:author` instead of `:author_first_name` in a `sort_link`.

```erb
<%= sort_link(@q, :author) %>
```

Note that using `:author_first_name_or_author_last_name_cont` would produce an invalid sql query. In those cases, Ransack ignores the sorting clause.



### Problem with DISTINCT selects

If passed `distinct: true`, `result` will generate a `SELECT DISTINCT` to
avoid returning duplicate rows, even if conditions on a join would otherwise
result in some. It generates the same SQL as calling `uniq` on the relation.

Please note that for many databases, a sort on an associated table's columns
may result in invalid SQL with `distinct: true` -- in those cases, you
will need to modify the result as needed to allow these queries to work.

For example, you could call joins and includes on the result which has the
effect of adding those tables columns to the select statement, overcoming
the issue, like so:

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result(distinct: true)
              .includes(:articles)
              .joins(:articles)
              .page(params[:page])
end
```

If the above doesn't help, you can also use ActiveRecord's `select` query
to explicitly add the columns you need, which brute force's adding the
columns you need that your SQL engine is complaining about, you need to
make sure you give all of the columns you care about, for example:

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result(distinct: true)
              .select('people.*, articles.name, articles.description')
              .page(params[:page])
end
```

Another method to approach this when using Postgresql is to use ActiveRecords's `.includes` in combination with `.group` instead of `distinct: true`.

For example:
```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result
              .group('persons.id')
              .includes(:articles)
              .page(params[:page])
end

```

A final way of last resort is to call `to_a.uniq` on the collection at the end
with the caveat that the de-duping is taking place in Ruby instead of in SQL,
which is potentially slower and uses more memory, and that it may display
awkwardly with pagination if the number of results is greater than the page size.

For example:

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result.includes(:articles).page(params[:page]).to_a.uniq
end
```

#### `PG::UndefinedFunction: ERROR: could not identify an equality operator for type json`

If you get the above error while using `distinct: true` that means that
one of the columns that Ransack is selecting is a `json` column.
PostgreSQL does not provide comparison operators for the `json` type.  While
it is possible to work around this, in practice it's much better to convert those
to `jsonb`, as [recommended by the PostgreSQL documentation](https://www.postgresql.org/docs/9.6/static/datatype-json.html).

### Authorization (allowlisting/denylisting)

By default, searching and sorting are authorized on any column of your model
and no class methods/scopes are whitelisted.

Ransack adds four methods to `ActiveRecord::Base` that you can redefine as
class methods in your models to apply selective authorization:

- `ransackable_attributes`
- `ransackable_associations`
- `ransackable_scopes`
- `ransortable_attributes`

Here is how these four methods are implemented in Ransack:

```ruby
  # `ransackable_attributes` by default returns all column names
  # and any defined ransackers as an array of strings.
  # For overriding with a whitelist array of strings.
  #
  def ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  # `ransackable_associations` by default returns the names
  # of all associations as an array of strings.
  # For overriding with a whitelist array of strings.
  #
  def ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

  # `ransortable_attributes` by default returns the names
  # of all attributes available for sorting as an array of strings.
  # For overriding with a whitelist array of strings.
  #
  def ransortable_attributes(auth_object = nil)
    ransackable_attributes(auth_object)
  end

  # `ransackable_scopes` by default returns an empty array
  # i.e. no class methods/scopes are authorized.
  # For overriding with a whitelist array of *symbols*.
  #
  def ransackable_scopes(auth_object = nil)
    []
  end
```

Any values not returned from these methods will be ignored by Ransack, i.e.
they are not authorized.

All four methods can receive a single optional parameter, `auth_object`. When
you call the search or ransack method on your model, you can provide a value
for an `auth_object` key in the options hash which can be used by your own
overridden methods.

Here is an example that puts all this together, adapted from
[this blog post by Ernie Miller](http://erniemiller.org/2012/05/11/why-your-ruby-class-macros-might-suck-mine-did/).
In an `Article` model, add the following `ransackable_attributes` class method
(preferably private):

```ruby
class Article < ActiveRecord::Base
  def self.ransackable_attributes(auth_object = nil)
    if auth_object == :admin
      # whitelist all attributes for admin
      super
    else
      # whitelist only the title and body attributes for other users
      super & %w(title body)
    end
  end

  private_class_method :ransackable_attributes
end
```

Here is example code for the `articles_controller`:

```ruby
class ArticlesController < ApplicationController
  def index
    @q = Article.ransack(params[:q], auth_object: set_ransack_auth_object)
    @articles = @q.result
  end

  private

  def set_ransack_auth_object
    current_user.admin? ? :admin : nil
  end
end
```

Trying it out in `rails console`:

```ruby
> Article
=> Article(id: integer, person_id: integer, title: string, body: text)

> Article.ransackable_attributes
=> ["title", "body"]

> Article.ransackable_attributes(:admin)
=> ["id", "person_id", "title", "body"]

> Article.ransack(id_eq: 1).result.to_sql
=> SELECT "articles".* FROM "articles"  # Note that search param was ignored!

> Article.ransack({ id_eq: 1 }, { auth_object: nil }).result.to_sql
=> SELECT "articles".* FROM "articles"  # Search param still ignored!

> Article.ransack({ id_eq: 1 }, { auth_object: :admin }).result.to_sql
=> SELECT "articles".* FROM "articles"  WHERE "articles"."id" = 1
```

That's it! Now you know how to whitelist/blacklist various elements in Ransack.

### Handling unknown predicates or attributes

By default, Ransack will ignore any unknown predicates or attributes:

```ruby
Article.ransack(unknown_attr_eq: 'Ernie').result.to_sql
=> SELECT "articles".* FROM "articles"
```

Ransack may be configured to raise an error if passed an unknown predicate or
attributes, by setting the `ignore_unknown_conditions` option to `false` in your
Ransack initializer file at `config/initializers/ransack.rb`:

```ruby
Ransack.configure do |c|
  # Raise errors if a query contains an unknown predicate or attribute.
  # Default is true (do not raise error on unknown conditions).
  c.ignore_unknown_conditions = false
end
```

```ruby
Article.ransack(unknown_attr_eq: 'Ernie')
# ArgumentError (Invalid search term unknown_attr_eq)
```

As an alternative to setting a global configuration option, the `.ransack!`
class method also raises an error if passed an unknown condition:

```ruby
Article.ransack!(unknown_attr_eq: 'Ernie')
# ArgumentError: Invalid search term unknown_attr_eq
```

This is equivalent to the `ignore_unknown_conditions` configuration option,
except it may be applied on a case-by-case basis.

### Using Scopes/Class Methods

Continuing on from the preceding section, searching by scopes requires defining
a whitelist of `ransackable_scopes` on the model class. The whitelist should be
an array of *symbols*. By default, all class methods (e.g. scopes) are ignored.
Scopes will be applied for matching `true` values, or for given values if the
scope accepts a value:

```ruby
class Employee < ActiveRecord::Base
  scope :activated, ->(boolean = true) { where(active: boolean) }
  scope :salary_gt, ->(amount) { where('salary > ?', amount) }

  # Scopes are just syntactical sugar for class methods, which may also be used:

  def self.hired_since(date)
    where('start_date >= ?', date)
  end

  def self.ransackable_scopes(auth_object = nil)
    if auth_object.try(:admin?)
      # allow admin users access to all three methods
      %i(activated hired_since salary_gt)
    else
      # allow other users to search on `activated` and `hired_since` only
      %i(activated hired_since)
    end
  end
end

Employee.ransack({ activated: true, hired_since: '2013-01-01' })

Employee.ransack({ salary_gt: 100_000 }, { auth_object: current_user })
```

In Rails 3 and 4, if the `true` value is being passed via url params or some
other mechanism that will convert it to a string, the true value may not be
passed to the ransackable scope unless you wrap it in an array
(i.e. `activated: ['true']`). Ransack will take care of changing 'true' into a
boolean. This is currently resolved in Rails 5 :smiley:

However, perhaps you have `user_id: [1]` and you do not want Ransack to convert
1 into a boolean. (Values sanitized to booleans can be found in the
[constants.rb](https://github.com/activerecord-hackery/ransack/blob/master/lib/ransack/constants.rb#L28)).
To turn this off globally, and handle type conversions yourself, set
`sanitize_custom_scope_booleans` to false in an initializer file like
config/initializers/ransack.rb:

```ruby
Ransack.configure do |c|
  c.sanitize_custom_scope_booleans = false
end
```

To turn this off on a per-scope basis Ransack adds the following method to
`ActiveRecord::Base` that you can redefine to selectively override sanitization:

`ransackable_scopes_skip_sanitize_args`

Add the scope you wish to bypass this behavior to ransackable_scopes_skip_sanitize_args:

```ruby
def self.ransackable_scopes_skip_sanitize_args
  [:scope_to_skip_sanitize_args]
end
```

Scopes are a recent addition to Ransack and currently have a few caveats:
First, a scope involving child associations needs to be defined in the parent
table model, not in the child model. Second, scopes with an array as an
argument are not easily usable yet, because the array currently needs to be
wrapped in an array to function (see
[this issue](https://github.com/activerecord-hackery/ransack/issues/404)),
which is not compatible with Ransack form helpers. For this use case, it may be
better for now to use [ransackers](https://github.com/activerecord-hackery/ransack/wiki/Using-Ransackers) instead,
where feasible. Pull requests with solutions and tests are welcome!

### Grouping queries by OR instead of AND

The default `AND` grouping can be changed to `OR` by adding `m: 'or'` to the
query hash.

You can easily try it in your controller code by changing `params[:q]` in the
`index` action to `params[:q].try(:merge, m: 'or')` as follows:

```ruby
def index
  @q = Artist.ransack(params[:q].try(:merge, m: 'or'))
  @artists = @q.result
end
```
Normally, if you wanted users to be able to toggle between `AND` and `OR`
query grouping, you would probably set up your search form so that `m` was in
the URL params hash, but here we assigned `m` manually just to try it out
quickly.

Alternatively, trying it in the Rails console:

```ruby
artists = Artist.ransack(name_cont: 'foo', style_cont: 'bar', m: 'or')
=> Ransack::Search<class: Artist, base: Grouping <conditions: [
  Condition <attributes: ["name"], predicate: cont, values: ["foo"]>,
  Condition <attributes: ["style"], predicate: cont, values: ["bar"]>
  ], combinator: or>>

artists.result.to_sql
=> "SELECT \"artists\".* FROM \"artists\"
    WHERE ((\"artists\".\"name\" ILIKE '%foo%'
    OR \"artists\".\"style\" ILIKE '%bar%'))"
```

The combinator becomes `or` instead of the default `and`, and the SQL query
becomes `WHERE...OR` instead of `WHERE...AND`.

This works with associations as well. Imagine an Artist model that has many
Memberships, and many Musicians through Memberships:

```ruby
artists = Artist.ransack(name_cont: 'foo', musicians_email_cont: 'bar', m: 'or')
=> Ransack::Search<class: Artist, base: Grouping <conditions: [
  Condition <attributes: ["name"], predicate: cont, values: ["foo"]>,
  Condition <attributes: ["musicians_email"], predicate: cont, values: ["bar"]>
  ], combinator: or>>

artists.result.to_sql
=> "SELECT \"artists\".* FROM \"artists\"
    LEFT OUTER JOIN \"memberships\"
      ON \"memberships\".\"artist_id\" = \"artists\".\"id\"
    LEFT OUTER JOIN \"musicians\"
      ON \"musicians\".\"id\" = \"memberships\".\"musician_id\"
    WHERE ((\"artists\".\"name\" ILIKE '%foo%'
    OR \"musicians\".\"email\" ILIKE '%bar%'))"
```

### Using SimpleForm

If you would like to combine the Ransack and SimpleForm form builders, set the
`RANSACK_FORM_BUILDER` environment variable before Rails boots up, e.g. in
`config/application.rb` before `require 'rails/all'` as shown below (and add
`gem 'simple_form'` in your Gemfile).

```ruby
require File.expand_path('../boot', __FILE__)
ENV['RANSACK_FORM_BUILDER'] = '::SimpleForm::FormBuilder'
require 'rails/all'
```
