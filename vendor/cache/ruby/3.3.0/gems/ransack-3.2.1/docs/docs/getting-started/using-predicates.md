---
title: Using Predicates
---

The primary method of searching in Ransack is by using what is known as *predicates*.

Predicates are used within Ransack search queries to determine what information to
match. For instance, the `cont` predicate will check to see if an attribute called
"first_name" contains a value using a wildcard query:

```ruby
>> User.ransack(first_name_cont: 'Rya').result.to_sql
=> SELECT "users".* FROM "users"  WHERE ("users"."first_name" LIKE '%Rya%')
```

You can also combine predicates for OR queries:
```ruby
>> User.ransack(first_name_or_last_name_cont: 'Rya').result.to_sql
=> SELECT "users".* FROM "users"  WHERE ("users"."first_name" LIKE '%Rya%'
   OR "users"."last_name" LIKE '%Rya%')
```

The syntax for `OR` queries on an associated model is not immediately obvious, but makes sense. Assuming a `User` `has_one` `Account` and the `Account` has `attributes` `foo` and `bar`:

```ruby
>> User.ransack(account_foo_or_account_bar_cont: 'val').result.to_sql
=> SELECT "users".* FROM "users" INNER JOIN accounts ON accounts.user_id = users.id WHERE ("accounts.foo LIKE '%val%' OR accounts.bar LIKE '%val%')
```

Below is a list of the built-in predicates of Ransack and their opposites. You may already
be familiar with some of the predicates, as they also exist in the ARel library.

If you want to add your own, please
see the [[Custom-Predicates|Custom Predicates]] page.

**Please note:** any attempt to use a predicate for an attribute that does not exist will
*silently fail*. For instance, this will not work when there is no `name` attribute:

```ruby
>> User.ransack(name_cont: 'Rya').result.to_sql
=> "SELECT "users".* FROM "users"
```

## eq (equals)

The `eq` predicate returns all records where a field is *exactly* equal to a given value:

```ruby
>> User.ransack(first_name_eq: 'Ryan').result.to_sql
=> SELECT "users".* FROM "users" WHERE "users"."first_name" = 'Ryan'
```

**Opposite: `not_eq`**

## matches

The `matches` predicate returns all records where a field is like a given value:

```ruby
>> User.ransack(first_name_matches: 'Ryan').result.to_sql
=> SELECT "users".* FROM "users" WHERE ("users"."first_name" LIKE 'Ryan')
```

On Postgres, the case-insensitive ILIKE will be used.

**Opposite: `does_not_match`**

*Note: If you want to do wildcard matching, you may be looking for the `cont`/`not_cont`
predicates instead.*

## lt (less than)

The `lt` predicate returns all records where a field is less than a given value:

```ruby
>> User.ransack(age_lt: 25).result.to_sql
=> SELECT "users".* FROM "users" WHERE ("users"."age" < 25)
```

**Opposite: `gteq` (greater than or equal to)**

## lteq (less than or equal to)

The `lteq` predicate returns all records where a field is less than *or equal to* a given value:

```ruby
>> User.ransack(age_lteq: 25).result.to_sql
=> SELECT "users".* FROM "users" WHERE ("users"."age" <= 25)
```

**Opposite: `gt` (greater than)**

## in

The `in` predicate returns all records where a field is within a specified list:

```ruby
>> User.ransack(age_in: 20..25).result.to_sql
=> SELECT "users".* FROM "users" WHERE "users"."age" IN (20, 21, 22, 23, 24, 25)
```

It can also take an array:

```ruby
>> User.ransack(age_in: [20, 21, 22, 23, 24, 25]).result.to_sql
=> SELECT "users".* FROM "users" WHERE "users"."age" IN (20, 21, 22, 23, 24, 25)
```

**Opposite: `not_in`**

## cont

The `cont` predicate returns all records where a field contains a given value:

```ruby
>> User.ransack(first_name_cont: 'Rya').result.to_sql
=> SELECT "users".* FROM "users"  WHERE ("users"."first_name" LIKE '%Rya%')
```

**Opposite: `not_cont`**

## cont_any (contains any)

The `cont_any` predicate returns all records where a field contains any of the given values:

```ruby
>> User.ransack(first_name_cont_any: %w(Rya Lis)).result.to_sql
=> SELECT "users".* FROM "users"  WHERE (("users"."first_name" LIKE '%Rya%' OR "users"."first_name" LIKE '%Lis%'))
```

**Opposite: `not_cont_any`**


## cont_all (contains all)

The `cont_all` predicate returns all records where a field contains all of the given values:

```ruby
>> User.ransack(city_cont_all: %w(Grand Rapids)).result.to_sql
=> SELECT "users".* FROM "users"  WHERE (("users"."city" LIKE '%Grand%' AND "users"."city" LIKE '%Rapids%'))
```

**Opposite: `not_cont_all`**


## i_cont

The `i_cont` case-insensitive predicate returns all records where a field contains a given value and ignores case:

```ruby
>> User.ransack(first_name_i_cont: 'Rya').result.to_sql
=> SELECT "users".* FROM "users"  WHERE (LOWER("users"."first_name") LIKE '%rya%')
```

**Opposite: `not_i_cont`**

## i_cont_any

The `i_cont_any` case-insensitive predicate returns all records where a field contains any of the given values and ignores case:

```ruby
>> User.ransack(first_name_i_cont_any: %w(Rya Lis)).result.to_sql
=> SELECT "users".* FROM "users"  WHERE ((LOWER("users"."first_name") LIKE '%rya%' OR LOWER("users"."first_name") LIKE '%lis%'))
```

**Opposite: `not_i_cont_any`**


## i_cont_all

The `i_cont_all` case-insensitive predicate returns all records where a field contains all of the given values and ignores case:

```ruby
>> User.ransack(city_i_cont_all: %w(Grand Rapids)).result.to_sql
=> SELECT "users".* FROM "users"  WHERE ((LOWER("users"."city") LIKE '%grand%' AND LOWER("users"."city") LIKE '%rapids%'))
```

**Opposite: `not_i_cont_all`**

## start (starts with)

The `start` predicate returns all records where a field begins with a given value:

```ruby
>> User.ransack(first_name_start: 'Rya').result.to_sql
=> SELECT "users".* FROM "users"  WHERE ("users"."first_name" LIKE 'Rya%')
```

**Opposite: `not_start`**

## end (ends with)

The `end` predicate returns all records where a field ends with a given value:

```ruby
>> User.ransack(first_name_end: 'yan').result.to_sql
=> SELECT "users".* FROM "users"  WHERE ("users"."first_name" LIKE '%yan')
```

**Opposite: `not_end`**

## true

The `true` predicate returns all records where a field is true. The '1' indicates that
to Ransack that you indeed want to check the truthiness of this field. The other truthy
values are 'true', 'TRUE', 't' or 'T'.

```ruby
>> User.ransack(awesome_true: '1').result.to_sql
=> SELECT "users".* FROM "users"  WHERE ("users"."awesome" = 't')
```

*Note: different database systems use different values to represent truth. In the above
example, we are using SQLite3.*

**Opposite: `not_true`**

## false

The `false` predicate returns all records where a field is false.

```ruby
>> User.ransack(awesome_false: '1').result.to_sql
=> SELECT "users".* FROM "users"  WHERE ("users"."awesome" = 'f')
```

**Opposite: `not_false`**

*Note: the `false` predicate may be considered the opposite of the `true` predicate if the field does not contain `null` values. Otherwise, use `not_false`.*

## present

The `present` predicate returns all records where a field is present (not null and not a
blank string).

```ruby
>> User.ransack(first_name_present: '1').result.to_sql
=> SELECT "users".* FROM "users"  WHERE (("users"."first_name" IS NOT NULL AND "users"."first_name" != ''))
```

**Opposite: `blank`**

## null

The `null` predicate returns all records where a field is null:

```ruby
>> User.ransack(first_name_null: 1).result.to_sql
=> SELECT "users".* FROM "users"  WHERE "users"."first_name" IS NULL
```

**Opposite: `not_null`**

# URL parameter structure

The search parameters are passed to ransack as a hash. The URL representation of this hash uses the bracket notation: ```hash_name[key]=value```. The hash_name is the parameter which is defined in the controller, for instance ```q```. The key is the attribute and search predicate compound, for instance ```first_name_cont```, the value is the search parameter. When searching without using the search form helpers this URL structure needs to be created manually.

For example, the URL layout for searching and sorting users could looks like this:

```
/users.json?q[first_name_cont]=pete&q[last_name_cont]=jack&q[s]=created_at+desc
```

_Note that the sorting parameter ```s``` is nested within the ```q``` hash._

When using JavaScript to create such a URL, a matching jQuery request could look like this:

```javascript
$.ajax({
  url: "/users.json",
  data: {
    q: {
      first_name_cont: "pete",
      last_name_cont: "jack",
      s: "created_at desc"
    }
  },
  success: function (data){
    console.log(data);
  }
});
```
