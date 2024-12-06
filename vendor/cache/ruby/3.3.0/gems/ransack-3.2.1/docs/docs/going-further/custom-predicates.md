---
sidebar_position: 1
title: Custom predicates
---

If you'd like to add your own custom Ransack predicates:

```ruby
# config/initializers/ransack.rb

Ransack.configure do |config|
  config.add_predicate 'equals_diddly', # Name your predicate
    # What non-compound ARel predicate will it use? (eq, matches, etc)
    arel_predicate: 'eq',
    # Format incoming values as you see fit. (Default: Don't do formatting)
    formatter: proc { |v| "#{v}-diddly" },
    # Validate a value. An "invalid" value won't be used in a search.
    # Below is default.
    validator: proc { |v| v.present? },
    # Should compounds be created? Will use the compound (any/all) version
    # of the arel_predicate to create a corresponding any/all version of
    # your predicate. (Default: true)
    compounds: true,
    # Force a specific column type for type-casting of supplied values.
    # (Default: use type from DB column)
    type: :string,
    # Use LOWER(column on database).
    # (Default: false)
    case_insensitive: true
end
```
You can check all Arel predicates [here](https://github.com/rails/rails/blob/main/activerecord/lib/arel/predications.rb).

If Arel does not have the predicate you are looking for, consider monkey patching it:

```ruby
# config/initializers/ransack.rb

module Arel
  module Predications
    def gteq_or_null(other)
      left = gteq(other)
      right = eq(nil)
      left.or(right)
    end
  end
end

Ransack.configure do |config|
  config.add_predicate 'gteq_or_null', arel_predicate: 'gteq_or_null'
end
```
