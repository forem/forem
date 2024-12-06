# rolify [![Gem Version](https://badge.fury.io/rb/rolify.svg)](http://badge.fury.io/rb/rolify) [![build status](https://travis-ci.org/RolifyCommunity/rolify.svg)](http://travis-ci.org/RolifyCommunity/rolify) [![Code Climate](https://codeclimate.com/github/RolifyCommunity/rolify.svg)](https://codeclimate.com/github/RolifyCommunity/rolify) [![Coverage Status](https://coveralls.io/repos/RolifyCommunity/rolify/badge.svg?branch=master&service=github)](https://coveralls.io/github/RolifyCommunity/rolify?branch=master)

Very simple Roles library without any authorization enforcement supporting scope on resource object.

Let's see an example:

```ruby
user.has_role?(:moderator, @forum)
=> false # if user is moderator of another Forum
```

This library can be easily integrated with any authentication gem ([devise](https://github.com/plataformatec/devise), [Authlogic](https://github.com/binarylogic/authlogic), [Clearance](https://github.com/thoughtbot/clearance)) and authorization gem<span style="color: red"><strong>*</strong></span> ([CanCanCan](https://github.com/CanCanCommunity/cancancan), [authority](https://github.com/nathanl/authority), [Pundit](https://github.com/elabs/pundit))

<span style="color: red"><strong>*</strong></span>: authorization gem that doesn't provide a role class

## Requirements

* Rails >= 4.2
* ActiveRecord >= 4.2 <b>or</b> Mongoid >= 4.0
* supports ruby 2.2+, JRuby 1.6.0+ (in 1.9 mode) and Rubinius 2.0.0dev (in 1.9 mode)
* support of ruby 1.8 has been dropped due to Mongoid >=3.0 that only supports 1.9 new hash syntax

## Installation

Add this to your Gemfile and run the `bundle` command.

```ruby
gem "rolify"
```

## Getting Started

### 1. Generate Role Model

First, use the generator to setup Rolify. Role and User class are the default names. However, you can specify any class name you want. For the User class name, you would probably use the one provided by your authentication solution.

If you want to use Mongoid instead of ActiveRecord, just add `--orm=mongoid` argument, and skip to step #3.

```
rails g rolify Role User
```

**NB** for versions of Rolify prior to 3.3, use:

```
rails g rolify:role Role User
```

The generator will create your Role model, add a migration file, and update your User class with new class methods.

### 2. Run the migration (only required when using ActiveRecord)

Let's migrate!

```
rake db:migrate
```

### 3.1 Configure your user model

This gem adds the `rolify` method to your User class. You can also specify optional callbacks on the User class for when roles are added or removed:

```ruby
class User < ActiveRecord::Base
  rolify :before_add => :before_add_method

  def before_add_method(role)
    # do something before it gets added
  end
end
```

The `rolify` method accepts the following callback options:

- `before_add`
- `after_add`
- `before_remove`
- `after_remove`

Mongoid callbacks are also supported and works the same way.

The `rolify` method also accepts the `inverse_of` option if you need to disambiguate the relationship.

### 3.2 Configure your resource models

In the resource models you want to apply roles on, just add ``resourcify`` method.
For example, on this ActiveRecord class:

```ruby
class Forum < ActiveRecord::Base
  resourcify
end
```

### 3.3 Assign default role

```ruby
class User < ActiveRecord::Base
  after_create :assign_default_role

  def assign_default_role
    self.add_role(:newuser) if self.roles.blank?
  end
end
```

### 4. Add a role to a user

To define a global role:

```ruby
user = User.find(1)
user.add_role :admin
```

To define a role scoped to a resource instance:

```ruby
user = User.find(2)
user.add_role :moderator, Forum.first
```

To define a role scoped to a resource class:

```ruby
user = User.find(3)
user.add_role :moderator, Forum
```

Remove role:
```ruby
user = User.find(3)
user.remove_role :moderator
```

That's it!

### 5. Role queries

To check if a user has a global role:

```ruby
user = User.find(1)
user.add_role :admin # sets a global role
user.has_role? :admin
=> true
```

To check if a user has a role scoped to a resource instance:

```ruby
user = User.find(2)
user.add_role :moderator, Forum.first # sets a role scoped to a resource instance
user.has_role? :moderator, Forum.first
=> true
user.has_role? :moderator, Forum.last
=> false
```

To check if a user has a role scoped to a resource class:

```ruby
user = User.find(3)
user.add_role :moderator, Forum # sets a role scoped to a resource class
user.has_role? :moderator, Forum
=> true
user.has_role? :moderator, Forum.first
=> true
user.has_role? :moderator, Forum.last
=> true
```

A global role overrides resource role request:

```ruby
user = User.find(4)
user.add_role :moderator # sets a global role
user.has_role? :moderator, Forum.first
=> true
user.has_role? :moderator, Forum.last
=> true
```

To check if a user has the exact role scoped to a resource class:

```ruby
user = User.find(5)
user.add_role :moderator # sets a global role
user.has_role? :moderator, Forum.first
=> true
user.has_strict_role? :moderator, Forum.last
=> false
```

### 6. Resource roles querying

Starting from rolify 3.0, you can search roles on instance level or class level resources.

#### Instance level

```ruby
forum = Forum.first
forum.roles
# => [ list of roles that are only bound to forum instance ]
forum.applied_roles
# => [ list of roles bound to forum instance and to the Forum class ]
```

#### Class level

```ruby
Forum.with_role(:admin)
# => [ list of Forum instances that have role "admin" bound to them ]
Forum.without_role(:admin)
# => [ list of Forum instances that do NOT have role "admin" bound to them ]
Forum.with_role(:admin, current_user)
# => [ list of Forum instances that have role "admin" bound to them and belong to current_user roles ]
Forum.with_roles([:admin, :user], current_user)
# => [ list of Forum instances that have role "admin" or "user" bound to them and belong to current_user roles ]

User.with_any_role(:user, :admin)
# => [ list of User instances that have role "admin" or "user" bound to them ]
User.with_role(:site_admin, current_site)
# => [ list of User instances that have a scoped role of "site_admin" to a site instance ]
User.with_role(:site_admin, :any)
# => [ list of User instances that have a scoped role of "site_admin" for any site instances ]
User.with_all_roles(:site_admin, :admin)
# => [ list of User instances that have a role of "site_admin" and a role of "admin" bound to it ]

Forum.find_roles
# => [ list of roles that are bound to any Forum instance or to the Forum class ]
Forum.find_roles(:admin)
# => [ list of roles that are bound to any Forum instance or to the Forum class, with "admin" as a role name ]
Forum.find_roles(:admin, current_user)
# => [ list of roles that are bound to any Forum instance, or to the Forum class with "admin" as a role name, and belongs to current_user ]
```

### Strict Mode

```ruby
class User < ActiveRecord::Base
  rolify strict: true
end

@user = User.first

@user.add_role(:forum, Forum)
@user.add_role(:forum, Forum.first)

@user.has_role?(:forum, Forum) #=> true
@user.has_role?(:forum, Forum.first) #=> true
@user.has_role?(:forum, Forum.last) #=> false
```
I.e. you get true only on a role that you manually add.

### Cached Roles (to avoid N+1 issue)

```ruby
@user.add_role :admin, Forum
@user.add_role :member, Forum

users = User.with_role(:admin, Forum).preload(:roles)
users.each do |user|
  user.has_cached_role?(:member, Forum) # no extra queries
end
```

This method should be used with caution. If you don't preload the roles, the `has_cached_role?` might return `false`. In the above example, it would return `false` for `@user.has_cached_role?(:member, Forum)`, because `User.with_role(:admin, Forum)` will load only the `:admin` roles.

## Resources

* [Wiki](https://github.com/RolifyCommunity/rolify/wiki)
* [Usage](https://github.com/RolifyCommunity/rolify/wiki/Usage): all the available commands
* [Tutorials](https://github.com/RolifyCommunity/rolify/wiki#wiki-tutorials):
  * [How-To use rolify with Devise and CanCanCan](https://github.com/RolifyCommunity/rolify/wiki/Devise---CanCanCan---rolify-Tutorial)
  * [Using rolify with Devise and Authority](https://github.com/RolifyCommunity/rolify/wiki/Using-rolify-with-Devise-and-Authority)
  * [Step-by-step tutorial](http://railsapps.github.com/tutorial-rails-bootstrap-devise-cancan.html) provided by [RailsApps](http://railsapps.github.com/)

## Upgrade from previous versions

Please read the [upgrade instructions](UPGRADE.rdoc).

## Known issues

* If you are using Mongoid and/or less-rails gem, please read [this](https://github.com/RolifyCommunity/rolify/wiki/FAQ#when-i-start-rails-using-server-console-whatever-i-get-this-error)
* Moped library (ruby driver for Mongodb used by Mongoid) doesn't support rubinius 2.2 yet (see https://github.com/mongoid/moped/issues/231)
* If you use Rails 4 and Mongoid, use Mongoid ~> 4. rolify is fully tested with Rails 4 and Mongoid 4.

## Questions or Problems?

If you have any issue or feature request with/for rolify, please create an new [issue on GitHub](https://github.com/RolifyCommunity/rolify/issues) **specifying the ruby runtime, rails and rolify versions you're using and the gems listed in your Gemfile**, or fork the project and send a pull request.

To get the specs running you should call `bundle` and then `rake`. See the spec/README for more information.
