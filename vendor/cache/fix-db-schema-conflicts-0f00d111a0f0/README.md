[![Build Status](https://travis-ci.org/jakeonrails/fix-db-schema-conflicts.svg?branch=master)](https://travis-ci.org/jakeonrails/fix-db-schema-conflicts)

# fix-db-schema-conflicts

It prevents db/schema.rb conflicts in your Rails projects when working with
multiple team members.

Specifically the situation that goes like this:

John is working on a feature, and adds a migration to create an `updated_at`
timestamp to `Task`. Sara is working on a different feature, and adds a
migration to create a `name` column to `Task`. They both run their migrations
locally, and then get a new copy of master with the other's feature and
migration. Then when they run migrations again, John's `tasks` table looks like
this:

    t.timestamp :updated_at
    t.string :name

And Sara's looks like this:

    t.string :name
    t.timestamp :updated_at

And every time they run migrations before committing new code, their
`db/schema.rb` file will be showing a change, because they are flipping the
order of the columns.

By using the fix-db-schema-conflicts gem, this problem goes away.

## How it works

This gem sorts the table, index, extension, and foreign key names before
outputting them to the schema.rb file. Additionally it runs Rubocop with the
auto-correct flag to ensure a consistent output format.

## Usage

You don't have to do anything different. It should just work. Simply run `rake
db:migrate` or `rake db:schema:dump` as you would before and 
`fix-db-schema-conflicts` will do the rest.

## Installation

Add this line to your application's Gemfile in your development group:

```ruby
gem 'fix-db-schema-conflicts'
```

And then execute:

    $ bundle

## Older versions of Rubocop:

If you wish to use a version of Rubocop `< 0.36.0` or below, use 
`gem 'fix-db-schema-conflicts', '~> 1.0.2'`

## Older versions of Ruby:

This gem only works with Ruby >= 2.2. Use versions 1.2.2 or below if you have an
old Ruby.

## Contributing

1. Fork it (https://github.com/[my-github-username]/fix-db-schema-conflicts/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

 - [@jakeonrails](https://github.com/jakeonrails) - Creator and maintainer
 - [@TCampaigne](https://github.com/TCampaigne)
 - [@Lordnibbler](https://github.com/Lordnibbler)
 - [@timdiggins](https://github.com/timdiggins)
 - [@zoras](https://github.com/zoras)
 - [@jensljungblad](https://github.com/jensljungblad)
 - [@vsubramanian](https://github.com/vsubramanian)
 - [@claytron](https://github.com/claytron)
 - [@amckinnell](https://github.com/amckinnell)
 - [@rosscooperman](https://github.com/rosscooperman)

## Releases
- 3.0.3
  - Added support for new Rubocop 0.53+ schema (rosscooperman)
- 3.0.2
  - Added support for new Rubocop 0.49+ schema (amckinnell)
- 3.0.1
  - Improve formatting to be more consistent (amckinnell)
  - Bump rake dependency to bypass a rake bug in older version (amckinnell)
- 3.0.0
  - Only support Ruby 2.2+ since lower versions haved reached EOL.
- 2.0.1
  - Fix bug that caused failure when project directory has a space in it
- 2.0.0
  - Allow usage of Rubocop >= 0.38.0
  - Remove Rails 5 deprecation warnings for using alias_method_chain
   - This upgrade breaks compatibility with Ruby 1.9x since 1.9x lacks #prepend
- 1.2.2
  - Remove dependency on sed
- 1.2.1
  - Upgrade Rubocop to get major performance boost
  - Add support for sorting of extensions
  - Fix spacing regression introduced by Rubocop upgrade
  - Add test suite and an integration test
