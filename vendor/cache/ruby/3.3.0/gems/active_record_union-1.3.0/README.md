# ActiveRecordUnion

[![Gem Version](https://badge.fury.io/rb/active_record_union.svg)](http://badge.fury.io/rb/active_record_union)
[![Build Status](https://travis-ci.org/brianhempel/active_record_union.svg)](https://travis-ci.org/brianhempel/active_record_union)

Use unions on ActiveRecord scopes without ugliness.

If you find yourself writing `pluck(:id)` and then feeding that into another query, you may be able to reduce the number of database requests by using a nested query or a UNION without writing crazy JOIN statements.

Quick usage examples:

```ruby
current_user.posts.union(Post.published)
current_user.posts.union(Post.published).where(id: [6, 7])
current_user.posts.union("published_at < ?", Time.now)
user_1.posts.union(user_2.posts).union(Post.published)
user_1.posts.union_all(user_2.posts)
```

ActiveRecordUnion is tested against Rails 4.2 and Rails 5.0. It may or may not work on Rails 4.0/4.1.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record_union'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_union

## Usage

ActiveRecordUnion adds `union` and `union_all` methods to `ActiveRecord::Relation` so we can easily gather together queries on mutiple scopes.

Consider some users with posts:

```ruby
class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user

  scope :published, -> { where("published_at < ?", Time.now) }
end
```

With ActiveRecordUnion, we can do:

```ruby
# the current user's (draft) posts and all published posts from anyone
current_user.posts.union(Post.published)
```

Which is equivalent to the following SQL:

```sql
SELECT "posts".* FROM (
  SELECT "posts".* FROM "posts"  WHERE "posts"."user_id" = 1
  UNION
  SELECT "posts".* FROM "posts"  WHERE (published_at < '2014-07-19 16:04:21.918366')
) "posts"
```

Because the `union` method returns another `ActiveRecord::Relation`, we can run further queries on the union.

```ruby
current_user.posts.union(Post.published).where(id: [6, 7])
```
```sql
SELECT "posts".* FROM (
  SELECT "posts".* FROM "posts"  WHERE "posts"."user_id" = 1
  UNION
  SELECT "posts".* FROM "posts"  WHERE (published_at < '2014-07-19 16:06:04.460771')
) "posts"  WHERE "posts"."id" IN (6, 7)
```

The `union` method can also accept anything that `where` does.

```ruby
current_user.posts.union("published_at < ?", Time.now)
# equivalent to...
current_user.posts.union(Post.where("published_at < ?", Time.now))
```

We can also chain `union` calls to UNION more than two scopes, though the UNIONs will be nested which may not be the prettiest SQL.

```ruby
user_1.posts.union(user_2.posts).union(Post.published)
# equivalent to...
[user_1.posts, user_2.posts, Post.published].inject(:union)
```
```sql
SELECT "posts".* FROM (
  SELECT "posts".* FROM (
    SELECT "posts".* FROM "posts"  WHERE "posts"."user_id" = 1
    UNION
    SELECT "posts".* FROM "posts"  WHERE "posts"."user_id" = 2
  ) "posts"
  UNION
  SELECT "posts".* FROM "posts"  WHERE (published_at < '2014-07-19 16:12:45.882648')
) "posts"
```

### UNION ALL

By default, UNION will remove any duplicates from the result set. If you don't care about duplicates or you know that the two queries you are combining will not have duplicates, you call use UNION ALL to tell the database to skip its deduplication step. In some cases this can give significant performance improvements.

```ruby
user_1.posts.union_all(user_2.posts)
```
```sql
SELECT "posts".* FROM (
  SELECT "posts".* FROM "posts" WHERE "posts"."user_id" = 1
  UNION ALL
  SELECT "posts".* FROM "posts" WHERE "posts"."user_id" = 2
) "posts"
```

## Caveats

There's a couple things to be aware of when using ActiveRecordUnion:

1. ActiveRecordUnion will raise an error if you try to UNION any relations that do any preloading/eager-loading. There's no sensible way to do the preloading in the subselects. If enough people complain, maybe, we can change ActiveRecordUnion to let the queries run anyway but without preloading any records.
2. There's no easy way to get SQLite to allow ORDER BY in the UNION subselects. If you get a syntax error, you can either write `my_relation.reorder(nil).union(other.reorder(nil))` or switch to Postgres.

## Another nifty way to reduce extra queries

ActiveRecord already supports turning scopes into nested queries in WHERE clauses. The nested relation defaults to selecting `id` by default.

For example, if a user `has_and_belongs_to_many :favorited_posts`, we can quickly find which of the current user's posts are liked by a certain other user.

```ruby
current_user.posts.where(id: other_user.favorited_posts)
```
```sql
SELECT "posts".* FROM "posts"
  WHERE "posts"."user_id" = 1
  AND "posts"."id" IN (
    SELECT "posts"."id"
      FROM "posts" INNER JOIN "user_favorited_posts" ON "posts"."id" = "user_favorited_posts"."post_id"
      WHERE "user_favorited_posts"."user_id" = 2
  )
```

If we want to select something other than `id`, we use `select` to specify. The following is equivalent to the above, but the query is done against the join table.

```ruby
current_user.posts.where(id: UserFavoritedPost.where(user_id: other_user.id).select(:post_id))
```
```sql
SELECT "posts".* FROM "posts"
  WHERE "posts"."user_id" = 1
  AND "posts"."id" IN (
    SELECT "user_favorited_posts"."post_id"
      FROM "user_favorited_posts"
      WHERE "user_favorited_posts"."user_id" = 2
  )
```

(The above example is illustrative only. It might be better with a JOIN.)

## State of the Union in ActiveRecord

Why does this gem exist?

Right now in ActiveRecord, if we call `scope.union` we get an `Arel::Nodes::Union` object instead of an `ActiveRecord::Relation`.

We could call `to_sql` on the Arel object and then use `find_by_sql`, but that's not super clean. Also, on Rails 4.0 and 4.1 if the original scopes included an association then the `to_sql` may produce a query with values that need to be bound (represented by `?`s in the SQL) and we have to provide those ourselves. (E.g. `user.posts.to_sql` produces `SELECT "posts".* FROM "posts"  WHERE "posts"."user_id" = ?`.) Rails 4.2's `to_sql` replaces the bind values before showing the SQL string and thus can more readily be used with `find_by_sql`. (E.g. Rails 4.2 `to_sql` would say `WHERE "posts"."user_id" = 1` instead of `WHERE "posts"."user_id" = ?`.)

While ActiveRecord may eventually have the ability to cleanly perform UNIONs, it's currently stalled. If you're interested, the relevant URLs as of July 2014 are:

https://github.com/rails/rails/issues/939 and
https://github.com/rails/arel/pull/239 and
https://github.com/yakaz/rails/commit/29b8ebd187e0888d5e71b2e1e4a12334860bc76c

This is a gem not a Rails pull request because the standard of code quality for a PR is a bit higher, and we'd have to wait for the PR to be merged and relased to use UNIONs. That said, the code here is fairly clean and it may end up in a PR sometime.

## Changelog

**1.3.0** - January 14, 2018
  - Ready for Rails 5.2! Updates provided by [@glebm](https://github.com/glebm).

**1.2.0** - June 26, 2016
  - Ready for Rails 5.0! Updates provided by [@glebm](https://github.com/glebm).

**1.1.1** - Mar 19, 2016
  - Fix broken polymorphic associations and joins due to improper handling of bind values. Fix by [@efradelos](https://github.com/efradelos), reported by [@Machiaweliczny](https://github.com/Machiaweliczny) and [@seandougall](https://github.com/seandougall).
  - Quote table name aliases properly. Reported by [@odedniv](https://github.com/odedniv).

**1.1.0** - Mar 29, 2015 - Add UNION ALL support, courtesy of [@pic](https://github.com/pic).

**1.0.1** - Sept 2, 2014 - Allow ORDER BY in UNION subselects for databases that support it (not SQLite).

**1.0.0** - July 24, 2014 - Initial release.

## License

ActiveRecordUnion is dedicated to the public domain by its author, Brian Hempel. No rights are reserved. No restrictions are placed on the use of ActiveRecordUnion. That freedom also means, of course, that no warrenty of fitness is claimed; use ActiveRecordUnion at your own risk.

This public domain dedication follows the the CC0 1.0 at https://creativecommons.org/publicdomain/zero/1.0/

## Contributing

1. Fork it ( https://github.com/brianhempel/active_record_union/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run the tests:
  1. Install MySQL and PostgreSQL.
  2. You need to be able to connect to a local MySQL and Postgres database as the default user, so the specs can create a `test_active_record_union` database. From a vanilla install of MariaDB from Homebrew, this just works. For Postgres installed by Homebrew, you may need to run `$ echo "create database my_computer_user_name;" | psql postgres` since the initial database created by Homebrew is named "postgres" but PG defaults to connecting to a database named after your username.
  3. Run `rake` to test with all supported Rails versions. All needed dependencies will be installed via Bundler (`gem install bundler` if you happen not to have Bundler yet).
  4. Run `rake test_rails_4_2` or `rake test_rails_5_2` etc. to test a specific Rails version.
4. There is also a `bin/console` command to load up a REPL for playing around
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request
