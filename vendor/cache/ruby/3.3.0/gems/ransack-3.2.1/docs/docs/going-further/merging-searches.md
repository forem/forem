---
sidebar_position: 5
title: Merging searches
---

To find records that match multiple searches, it's possible to merge all the ransack search conditions into an ActiveRecord relation to perform a single query. In order to avoid conflicts between joined table names it's necessary to set up a shared context to track table aliases used across all the conditions before initializing the searches:

```ruby
shared_context = Ransack::Context.for(Person)

search_parents = Person.ransack(
  { parent_name_eq: "A" }, context: shared_context
)

search_children = Person.ransack(
  { children_name_eq: "B" }, context: shared_context
)

shared_conditions = [search_parents, search_children].map { |search|
  Ransack::Visitor.new.accept(search.base)
}

Person.joins(shared_context.join_sources)
  .where(shared_conditions.reduce(&:or))
  .to_sql
```
Produces:
```sql
SELECT "people".*
FROM "people"
LEFT OUTER JOIN "people" "parents_people"
  ON "parents_people"."id" = "people"."parent_id"
LEFT OUTER JOIN "people" "children_people"
  ON "children_people"."parent_id" = "people"."id"
WHERE (
  ("parents_people"."name" = 'A' OR "children_people"."name" = 'B')
  )
ORDER BY "people"."id" DESC
```

Admittedly this is not as simple as it should be, but it's workable for now. (Implementing [issue 417](https://github.com/activerecord-hackery/ransack/issues/417) could make this more straightforward.)
