---
title: Polymorphic Searches
sidebar_position: 14
---

When making searches from polymorphic models it is necessary to specify the type of model you are searching. 

For example:

Given two models

```ruby
class House < ActiveRecord::Base
  has_one :location, as: :locatable
end

class Location < ActiveRecord::Base
  belongs_to :locatable, polymorphic: true
end
```

Normally (without polymorphic relationship) you would be able to search as per below:

```ruby
Location.ransack(locatable_number_eq: 100).result
```

However when this is searched you will get the following error

```ruby
ActiveRecord::EagerLoadPolymorphicError: Can not eagerly load the polymorphic association :locatable
```

In order to search for locations by house number when the relationship is polymorphic you have to specify the type of records you will be searching and construct your search as below:

```ruby
Location.ransack(locatable_of_House_type_number_eq: 100).result
```

note the `_of_House_type_` added to the search key. This allows Ransack to correctly specify the table names in SQL join queries.
