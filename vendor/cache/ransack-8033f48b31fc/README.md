# ![Ransack](./logo/ransack-h.png "Ransack")

**MAINTAINER WANTED** 

Please see the [Maintainer wanted issue](https://github.com/activerecord-hackery/ransack/issues/1159) if you are interested.

[![Build Status](https://travis-ci.org/activerecord-hackery/ransack.svg)](https://travis-ci.org/activerecord-hackery/ransack)
[![Gem Version](https://badge.fury.io/rb/ransack.svg)](http://badge.fury.io/rb/ransack)
[![Code Climate](https://codeclimate.com/github/activerecord-hackery/ransack/badges/gpa.svg)](https://codeclimate.com/github/activerecord-hackery/ransack)
[![Backers on Open Collective](https://opencollective.com/ransack/backers/badge.svg)](#backers) [![Sponsors on Open Collective](https://opencollective.com/ransack/sponsors/badge.svg)](#sponsors)

Ransack enables the creation of both
[simple](http://ransack-demo.herokuapp.com) and
[advanced](http://ransack-demo.herokuapp.com/users/advanced_search) search forms
for your Ruby on Rails application
([demo source code here](https://github.com/activerecord-hackery/ransack_demo)).
If you're looking for something that simplifies query generation at the model
or controller layer, you're probably not looking for Ransack (or MetaSearch,
for that matter). Try [Squeel](https://github.com/activerecord-hackery/squeel)
instead.

## Getting started

Ransack is compatible with Rails 6.0, 5.0, 5.1 and 5.2 on Ruby 2.3 and later.

In your Gemfile, for the last officially released gem:

```ruby
gem 'ransack'
```

If you would like to use the latest updates (recommended), use the `master`
branch:

```ruby
gem 'ransack', github: 'activerecord-hackery/ransack'
```

## Issues tracker

* Before filing an issue, please read the [Contributing Guide](CONTRIBUTING.md).
* File an issue if a bug is caused by Ransack, is new (has not already been reported), and _can be reproduced from the information you provide_.
* Contributions are welcome, but please do not add "+1" comments to issues or pull requests :smiley:
* Please do not use the issue tracker for personal support requests. Stack Overflow is a better place for that where a wider community can help you!

## Usage

Ransack can be used in one of two modes, simple or advanced.

### Simple Mode

This mode works much like MetaSearch, for those of you who are familiar with
it, and requires very little setup effort.

If you're coming from MetaSearch, things to note:

  1. The default param key for search params is now `:q`, instead of `:search`.
  This is primarily to shorten query strings, though advanced queries (below)
  will still run afoul of URL length limits in most browsers and require a
  switch to HTTP POST requests. This key is [configurable](https://github.com/activerecord-hackery/ransack/wiki/Configuration).

  2. `form_for` is now `search_form_for`, and validates that a Ransack::Search
  object is passed to it.

  3. Common ActiveRecord::Relation methods are no longer delegated by the
  search object. Instead, you will get your search results (an
  ActiveRecord::Relation in the case of the ActiveRecord adapter) via a call to
  `Ransack#result`.

#### In your controller

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result(distinct: true)
end
```
or without `distinct: true`, for sorting on an associated table's columns (in
this example, with preloading each Person's Articles and pagination):

```ruby
def index
  @q = Person.ransack(params[:q])
  @people = @q.result.includes(:articles).page(params[:page])

  # or use `to_a.uniq` to remove duplicates (can also be done in the view):
  @people = @q.result.includes(:articles).page(params[:page]).to_a.uniq
end
```

#### In your view

The two primary Ransack view helpers are `search_form_for` and `sort_link`,
which are defined in
[Ransack::Helpers::FormHelper](lib/ransack/helpers/form_helper.rb).

#### Ransack's `search_form_for` helper replaces `form_for` for creating the view search form

```erb
<%= search_form_for @q do |f| %>

  # Search if the name field contains...
  <%= f.label :name_cont %>
  <%= f.search_field :name_cont %>

  # Search if an associated articles.title starts with...
  <%= f.label :articles_title_start %>
  <%= f.search_field :articles_title_start %>

  # Attributes may be chained. Search multiple attributes for one value...
  <%= f.label :name_or_description_or_email_or_articles_title_cont %>
  <%= f.search_field :name_or_description_or_email_or_articles_title_cont %>

  <%= f.submit %>
<% end %>
```

The argument of `f.search_field` has to be in this form:
 `attribute_name[_or_attribute_name]..._predicate`

where `[_or_another_attribute_name]...` means any repetition of `_or_` plus the name of the attribute.

`cont` (contains) and `start` (starts with) are just two of the available
search predicates. See
[Constants](https://github.com/activerecord-hackery/ransack/blob/master/lib/ransack/constants.rb)
for a full list and the
[wiki](https://github.com/activerecord-hackery/ransack/wiki/Basic-Searching)
for more information.

The `search_form_for` answer format can be set like this:

```erb
<%= search_form_for(@q, format: :pdf) do |f| %>

<%= search_form_for(@q, format: :json) do |f| %>
```

#### Ransack's `sort_link` helper creates table headers that are sortable links

```erb
<%= sort_link(@q, :name) %>
```
Additional options can be passed after the column attribute, like a different
column title or a default sort order:

```erb
<%= sort_link(@q, :name, 'Last Name', default_order: :desc) %>
```

You can use a block if the link markup is hard to fit into the label parameter:

```erb
<%= sort_link(@q, :name) do %>
  <strong>Player Name</strong>
<% end %>
```

With a polymorphic association, you may need to specify the name of the link
explicitly to avoid an `uninitialized constant Model::Xxxable` error (see issue
[#421](https://github.com/activerecord-hackery/ransack/issues/421)):

```erb
<%= sort_link(@q, :xxxable_of_Ymodel_type_some_attribute, 'Attribute Name') %>
```

You can also sort on multiple fields by specifying an ordered array:

```erb
<%= sort_link(@q, :last_name, [:last_name, 'first_name asc'], 'Last Name') %>
```

In the example above, clicking the link will sort by `last_name` and then
`first_name`. Specifying the sort direction on a field in the array tells
Ransack to _always_ sort that particular field in the specified direction.

Multiple `default_order` fields may also be specified with a hash:

```erb
<%= sort_link(@q, :last_name, %i(last_name first_name),
  default_order: { last_name: 'asc', first_name: 'desc' }) %>
```

This example toggles the sort directions of both fields, by default
initially sorting the `last_name` field by ascending order, and the
`first_name` field by descending order.

In the case that you wish to sort by some complex value, such as the result
of a SQL function, you may do so using scopes. In your model, define scopes
whose names line up with the name of the virtual field you wish to sort by,
as so:

```ruby
class Person < ActiveRecord::Base
  scope :sort_by_reverse_name_asc, lambda { order("REVERSE(name) ASC") }
  scope :sort_by_reverse_name_desc, lambda { order("REVERSE(name) DESC") }
...
```

and you can then sort by this virtual field:

```erb
<%= sort_link(@q, :reverse_name) %>
```

The sort link order indicator arrows may be globally customized by setting a
`custom_arrows` option in an initializer file like
`config/initializers/ransack.rb`.

You can also enable a `default_arrow` which is displayed on all sortable fields
which are not currently used in the sorting. This is disabled by default so
nothing will be displayed:

```ruby
Ransack.configure do |c|
  c.custom_arrows = {
    up_arrow: '<i class="custom-up-arrow-icon"></i>',
    down_arrow: 'U+02193',
    default_arrow: '<i class="default-arrow-icon"></i>'
  }
end
```

All sort links may be displayed without the order indicator
arrows by setting `hide_sort_order_indicators` to true in the initializer file.
Note that this hides the arrows even if they were customized:

```ruby
Ransack.configure do |c|
  c.hide_sort_order_indicators = true
end
```

Without setting it globally, individual sort links may be displayed without
the order indicator arrow by passing `hide_indicator: true` in the sort link:

```erb
<%= sort_link(@q, :name, hide_indicator: true) %>
```

#### Ransack's `sort_url` helper is like a `sort_link` but returns only the url

`sort_url` has the same API as `sort_link`:

```erb
<%= sort_url(@q, :name, default_order: :desc) %>
```

```erb
<%= sort_url(@q, :last_name, [:last_name, 'first_name asc']) %>
```

```erb
<%= sort_url(@q, :last_name, %i(last_name first_name),
  default_order: { last_name: 'asc', first_name: 'desc' }) %>
```

### Advanced Mode

"Advanced" searches (ab)use Rails' nested attributes functionality in order to
generate complex queries with nested AND/OR groupings, etc. This takes a bit
more work but can generate some pretty cool search interfaces that put a lot of
power in the hands of your users. A notable drawback with these searches is
that the increased size of the parameter string will typically force you to use
the HTTP POST method instead of GET. :(

This means you'll need to tweak your routes...

```ruby
resources :people do
  collection do
    match 'search' => 'people#search', via: [:get, :post], as: :search
  end
end
```

... and add another controller action ...

```ruby
def search
  index
  render :index
end
```

... and update your `search_form_for` line in the view ...

```erb
<%= search_form_for @q, url: search_people_path,
                        html: { method: :post } do |f| %>
```

Once you've done so, you can make use of the helpers in [Ransack::Helpers::FormBuilder](lib/ransack/helpers/form_builder.rb) to
construct much more complex search forms, such as the one on the
[demo app](http://ransack-demo.herokuapp.com/users/advanced_search)
(source code [here](https://github.com/activerecord-hackery/ransack_demo)).

### Ransack #search method

Ransack will try to make the class method `#search` available in your
models, but if `#search` has already been defined elsewhere, you can always use
the default `#ransack` class method. So the following are equivalent:

```ruby
Article.ransack(params[:q])
Article.search(params[:q])
```

Users have reported issues of `#search` name conflicts with other gems, so
the `#search` method alias will be deprecated in the next major version of
Ransack (2.0). It's advisable to use the default `#ransack` instead.

For now, if Ransack's `#search` method conflicts with the name of another
method named `search` in your code or another gem, you may resolve it either by
patching the `extended` class_method in `Ransack::Adapters::ActiveRecord::Base`
to remove the line `alias :search :ransack unless base.respond_to? :search`, or
by placing the following line in your Ransack initializer file at
`config/initializers/ransack.rb`:

```ruby
Ransack::Adapters::ActiveRecord::Base.class_eval('remove_method :search')
```

### Associations

You can easily use Ransack to search for objects in `has_many` and `belongs_to`
associations.

Given these associations...

```ruby
class Employee < ActiveRecord::Base
  belongs_to :supervisor

  # has attributes first_name:string and last_name:string
end

class Department < ActiveRecord::Base
  has_many :supervisors

  # has attribute title:string
end

class Supervisor < ActiveRecord::Base
  belongs_to :department
  has_many :employees

  # has attribute last_name:string
end
```

... and a controller...

```ruby
class SupervisorsController < ApplicationController
  def index
    @q = Supervisor.ransack(params[:q])
    @supervisors = @q.result.includes(:department, :employees)
  end
end
```

... you might set up your form like this...

```erb
<%= search_form_for @q do |f| %>
  <%= f.label :last_name_cont %>
  <%= f.search_field :last_name_cont %>

  <%= f.label :department_title_cont %>
  <%= f.search_field :department_title_cont %>

  <%= f.label :employees_first_name_or_employees_last_name_cont %>
  <%= f.search_field :employees_first_name_or_employees_last_name_cont %>

  <%= f.submit "search" %>
<% end %>
...
<%= content_tag :table do %>
  <%= content_tag :th, sort_link(@q, :last_name) %>
  <%= content_tag :th, sort_link(@q, :department_title) %>
  <%= content_tag :th, sort_link(@q, :employees_last_name) %>
<% end %>
```

If you have trouble sorting on associations, try using an SQL string with the
pluralized table (`'departments.title'`,`'employees.last_name'`) instead of the
symbolized association (`:department_title)`, `:employees_last_name`).

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

### Search Matchers

List of all possible predicates


| Predicate | Description | Notes |
| ------------- | ------------- |-------- |
| `*_eq`  | equal  | |
| `*_not_eq` | not equal | |
| `*_matches` | matches with `LIKE` | e.g. `q[email_matches]=%@gmail.com`|
| `*_does_not_match` | does not match with `LIKE` | |
| `*_matches_any` | Matches any | |
| `*_matches_all` | Matches all  | |
| `*_does_not_match_any` | Does not match any | |
| `*_does_not_match_all` | Does not match all | |
| `*_lt` | less than | |
| `*_lteq` | less than or equal | |
| `*_gt` | greater than | |
| `*_gteq` | greater than or equal | |
| `*_present` | not null and not empty | Only compatible with string columns. Example: `q[name_present]=1` (SQL: `col is not null AND col != ''`) |
| `*_blank` | is null or empty. | (SQL: `col is null OR col = ''`) |
| `*_null` | is null | |
| `*_not_null` | is not null | |
| `*_in` | match any values in array | e.g. `q[name_in][]=Alice&q[name_in][]=Bob` |
| `*_not_in` | match none of values in array | |
| `*_lt_any` | Less than any |  SQL: `col < value1 OR col < value2` |
| `*_lteq_any` | Less than or equal to any | |
| `*_gt_any` | Greater than any | |
| `*_gteq_any` | Greater than or equal to any | |
| `*_lt_all` | Less than all | SQL: `col < value1 AND col < value2` |
| `*_lteq_all` | Less than or equal to all | |
| `*_gt_all` | Greater than all | |
| `*_gteq_all` | Greater than or equal to all | |
| `*_not_eq_all` | none of values in a set | |
| `*_start` | Starts with | SQL: `col LIKE 'value%'` |
| `*_not_start` | Does not start with | |
| `*_start_any` | Starts with any of | |
| `*_start_all` | Starts with all of | |
| `*_not_start_any` | Does not start with any of | |
| `*_not_start_all` | Does not start with all of | |
| `*_end` | Ends with | SQL: `col LIKE '%value'` |
| `*_not_end` | Does not end with | |
| `*_end_any` | Ends with any of | |
| `*_end_all` | Ends with all of | |
| `*_not_end_any` | | |
| `*_not_end_all` | | |
| `*_cont` | Contains value | uses `LIKE` |
| `*_cont_any` | Contains any of | |
| `*_cont_all` | Contains all of | |
| `*_not_cont` | Does not contain |
| `*_not_cont_any` | Does not contain any of | |
| `*_not_cont_all` | Does not contain all of | |
| `*_i_cont` | Contains value with case insensitive | uses `ILIKE` |
| `*_i_cont_any` | Contains any of values with case insensitive | |
| `*_i_cont_all` | Contains all of values with case insensitive | |
| `*_not_i_cont` | Does not contain with case insensitive |
| `*_not_i_cont_any` | Does not contain any of values with case insensitive | |
| `*_not_i_cont_all` | Does not contain all of values with case insensitive | |
| `*_true` | is true | |
| `*_false` | is false | |


(See full list: https://github.com/activerecord-hackery/ransack/blob/master/lib/ransack/locale/en.yml#L15 and [wiki](https://github.com/activerecord-hackery/ransack/wiki/Basic-Searching))

### Using Ransackers to add custom search functions via Arel

The main premise behind Ransack is to provide access to
**Arel predicate methods**. Ransack provides special methods, called
_ransackers_, for creating additional search functions via Arel. More
information about `ransacker` methods can be found [here in the wiki](https://github.com/activerecord-hackery/ransack/wiki/Using-Ransackers).
Feel free to contribute working `ransacker` code examples to the wiki!

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

### Authorization (whitelisting/blacklisting)

By default, searching and sorting are authorized on any column of your model
and no class methods/scopes are whitelisted.

Ransack adds four methods to `ActiveRecord::Base` that you can redefine as
class methods in your models to apply selective authorization:
`ransackable_attributes`, `ransackable_associations`, `ransackable_scopes` and
`ransortable_attributes`.

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

### I18n

Ransack translation files are available in
[Ransack::Locale](lib/ransack/locale). You may also be interested in one of the
many translations for Ransack available at
http://www.localeapp.com/projects/2999.

Predicate and attribute translations in forms may be specified as follows (see
the translation files in [Ransack::Locale](lib/ransack/locale) for more examples):

locales/en.yml:
```yml
en:
  ransack:
    asc: ascending
    desc: descending
    predicates:
      cont: contains
      not_cont: not contains
      start: starts with
      end: ends with
      gt: greater than
      lt: less than
    models:
      person: Passanger
    attributes:
      person:
        name: Full Name
      article:
        title: Article Title
        body: Main Content
```

Attribute names may also be changed globally, or under `activerecord`:

```yml
en:
  attributes:
    model_name:
      model_field1: field name1
      model_field2: field name2
  activerecord:
    attributes:
      namespace/article:
        title: AR Namespaced Title
      namespace_article:
        title: Old Ransack Namespaced Title
```

## Mongoid

Mongoid support has been moved to its own gem at [ransack-mongoid](https://github.com/activerecord-hackery/ransack-mongoid).
Ransack works with Mongoid in the same way as Active Record, except that with
Mongoid, associations are not currently supported. Demo source code may be found
[here](https://github.com/Zhomart/ransack-mongodb-demo). A `result` method
called on a `ransack` search returns a `Mongoid::Criteria` object:

```ruby
  @q = Person.ransack(params[:q])
  @people = @q.result # => Mongoid::Criteria

  # or you can add more Mongoid queries
  @people = @q.result.active.order_by(updated_at: -1).limit(10)
```

NOTE: Ransack currently works with either Active Record or Mongoid, but not
both in the same application. If both are present, Ransack will default to
Active Record only. The logic is contained in
`Ransack::Adapters#instantiate_object_mapper` should you need to override it.

## Semantic Versioning

Ransack attempts to follow semantic versioning in the format of `x.y.z`, where:

`x` stands for a major version (new features that are not backward-compatible).

`y` stands for a minor version (new features that are backward-compatible).

`z` stands for a patch (bug fixes).

In other words: `Major.Minor.Patch`.

## Contributions

To support the project:

* Consider supporting via [Open Collective](https://opencollective.com/ransack/backers/badge.svg)
* Use Ransack in your apps, and let us know if you encounter anything that's
broken or missing. A failing spec to demonstrate the issue is awesome. A pull
request with passing tests is even better!
* Before filing an issue or pull request, be sure to read and follow the
[Contributing Guide](CONTRIBUTING.md).
* Please use Stack Overflow or other sites for questions or discussion not
directly related to bug reports, pull requests, or documentation improvements.
* Spread the word on Twitter, Facebook, and elsewhere if Ransack's been useful
to you. The more people who are using the project, the quicker we can find and
fix bugs!

## Contributors

This project exists thanks to all the people who contribute. <img src="https://opencollective.com/ransack/contributors.svg?width=890&button=false" />

Ransack is a rewrite of [MetaSearch](https://github.com/activerecord-hackery/meta_search)
created by [Ernie Miller](http://twitter.com/erniemiller)
and developed/maintained by:

- [Greg Molnar](https://github.com/gregmolnar)
- [Deivid Rodriguez](https://github.com/deivid-rodriguez)
- [Sean Carroll](https://github.com/seanfcarroll)
- [Jon Atack](http://twitter.com/jonatack)
- [Ryan Bigg](http://twitter.com/ryanbigg)
- a great group of [contributors](https://github.com/activerecord-hackery/ransack/graphs/contributors).
- Ransack's logo is designed by [Anıl Kılıç](https://github.com/anilkilic).

While it supports many of the same features as MetaSearch, its underlying implementation differs greatly from MetaSearch, and backwards compatibility is not a design goal.



## Backers

Thank you to all our backers! 🙏 [[Become a backer](https://opencollective.com/ransack#backer)]

<a href="https://opencollective.com/ransack#backers" target="_blank"><img src="https://opencollective.com/ransack/backers.svg?width=890"></a>


## Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/ransack#sponsor)]

<a href="https://opencollective.com/ransack/sponsor/0/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/1/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/2/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/3/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/4/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/5/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/6/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/7/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/8/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/ransack/sponsor/9/website" target="_blank"><img src="https://opencollective.com/ransack/sponsor/9/avatar.svg"></a>
