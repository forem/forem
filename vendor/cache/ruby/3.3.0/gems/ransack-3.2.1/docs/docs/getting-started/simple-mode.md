---
sidebar_position: 1
title: Simple mode
---

# Simple Mode

Ransack can be used in one of two modes, simple or advanced. For
searching/filtering not requiring complex boolean logic, Ransack's simple
mode should meet your needs.

## In your controller

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
end
```

### Default search options

#### Search parameter

Ransack uses a default `:q` param key for search params. This may be changed by
setting the `search_key` option in a Ransack initializer file (typically
`config/initializers/ransack.rb`):

```ruby
Ransack.configure do |c|
  # Change default search parameter key name.
  # Default key name is :q
  c.search_key = :query
end
```

#### String search

After version 2.4.0 when searching a string query Ransack by default strips all whitespace around the query string.
This may be disabled by setting the `strip_whitespace` option in a Ransack initializer file:

```ruby
Ransack.configure do |c|
  # Change whitespace stripping behaviour.
  # Default is true
  c.strip_whitespace = false
end
```

## In your view

The two primary Ransack view helpers are `search_form_for` and `sort_link`,
which are defined in
[Ransack::Helpers::FormHelper](https://github.com/activerecord-hackery/ransack/lib/ransack/helpers/form_helper.rb).

### Form helper

Ransack's `search_form_for` helper replaces `form_for` for creating the view search form

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
search predicates.

The `search_form_for` answer format can be set like this:

```erb
<%= search_form_for(@q, format: :pdf) do |f| %>

<%= search_form_for(@q, format: :json) do |f| %>
```

### Search link helper

Ransack's `sort_link` helper creates table headers that are sortable links

```erb
<%= sort_link(@q, :name) %>
```
Additional options can be passed after the column parameter, like a different
column title or a default sort order.

If the first option after the column parameter is a String, it's considered a
custom label for the link:

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

If the first option after the column parameter and/or the label parameter is an
Array, it will be used for sorting on multiple fields:

```erb
<%= sort_link(@q, :last_name, [:last_name, 'first_name asc'], 'Last Name') %>
```

In the example above, clicking the link will sort by `last_name` and then
`first_name`. Specifying the sort direction on a field in the array tells
Ransack to _always_ sort that particular field in the specified direction.

Multiple `default_order` fields may also be specified with a trailing options
Hash:

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

The trailing options Hash can also be used for passing additional options to the
generated link, like `class:`.

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

### sort_url

Ransack's `sort_url` helper is like a `sort_link` but returns only the url

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

### PostgreSQL's sort option

The `NULLS FIRST` and `NULLS LAST` options can be used to determine whether nulls appear before or after non-null values in the sort ordering.

You may want to configure it like this:

```ruby
Ransack.configure do |c|
  c.postgres_fields_sort_option = :nulls_first # or :nulls_last
end
```

To treat nulls as having the lowest or highest value respectively. To force nulls to always be first or last, use

```ruby
Ransack.configure do |c|
  c.postgres_fields_sort_option = :nulls_always_first # or :nulls_always_last
end
```

See this feature: https://www.postgresql.org/docs/13/queries-order.html

#### Case Insensitive Sorting in PostgreSQL

In order to request PostgreSQL to do a case insensitive sort for all string columns of a model at once, Ransack can be extended by using this approach:

```ruby
module RansackObject

  def self.included(base)
    base.columns.each do |column|
      if column.type == :string
        base.ransacker column.name.to_sym, type: :string do
          Arel.sql("lower(#{base.table_name}.#{column.name})")
        end
      end
    end
  end
end
```

```ruby
class UserWithManyAttributes < ActiveRecord::Base
  include RansackObject
end
```

If this approach is taken, it is advisable to [add a functional index](https://www.postgresql.org/docs/13/citext.html).

This was originally asked in [a Ransack issue](https://github.com/activerecord-hackery/ransack/issues/1201) and a solution was found on [Stack Overflow](https://stackoverflow.com/a/34677378).
