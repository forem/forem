---
sidebar_position: 4
title: Form customisation
---

Predicate and attribute labels in forms may be specified with I18n in a translation file (see the locale files in [Ransack::Locale](https://github.com/activerecord-hackery/ransack/activerecord-hackery/ransack/tree/master/lib/ransack/locale) for more examples):

```yml
# locales/en.yml
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
    attributes:
      person:
        name: Full Name
      article:
        title: Article Title
        body: Main Content
```
The names of attribute fields may also be changed globally or under activerecord:

```yml
# locales/en.yml
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

To limit the predicates in the `predicate_select` form helper in a view template, pass an array of permitted predicates with `only`:

```erb
<%= f.predicate_select only: %i(cont not_cont eq not_eq blank null) %>
```

Compound predicates (`_any` & `_all`) may be removed by passing the option `compounds: false`.

```erb
<%= f.predicate_select compounds: false %>
```

Searchable attributes versus non-searchable ones may be specified as follows:

```ruby
def self.ransackable_attributes(auth_object = nil)
  %w(searchable_attribute_1 searchable_attribute_2 ...) + _ransackers.keys
end
```
