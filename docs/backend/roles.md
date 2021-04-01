---
title: Roles
---

# Roles

## What is a role?

If authorization is about who has permission to be allowed to do what you want
to do, then Roles are common patterns of authorization across users - reducing
the administrative overhead.

## Why do I need to know about roles?

Some bugs can only be seen for users with specific roles. You will need to
change the role to reproduce a problem.

## How do we implement roles in Forem?

Roles are implemented in this application using [Rolify][1]. The list of roles
can be found in [app/models/role.rb][2] and you can search for [has_role in the
codebase][3] to find which pages need which roles.

A new user starts without any roles, and there is no administrative way of
adding roles to users yet. To assign a user a role you will have to run commands
at the console.

## Example of adding permissions to a user

- open the Rails console

```shell
rails console
```

- after verifying the user `test_user_name` is missing the `trusted` role we
  proceed to add it and then verify the role has been added:

```ruby
> user = User.find_by(username: "test_user_name")
> user.has_role? :trusted
=> false

> user.add_role(:trusted)
=> #<Role:
...
name: "trusted"
.. >

> user.has_role? :trusted
=> true
```

Another common requirement is changing to the administrative role, and an
example of this is found [on the admin page][5].

## Verification

A more complex query to list all the users and their roles:

```ruby
User.joins(:roles).order(:id).group(:id).pluck(:id, :username, Arel.sql("array_agg(roles.name)"))
```

## Further Reading

1. [Rolify README.md][1]
2. [What is the purpose of Rolify?][4]
3. [Admin][5]

[1]: https://github.com/RolifyCommunity/rolify
[2]: https://github.com/forem/forem/blob/master/app/models/role.rb
[3]: https://github.com/forem/forem/search?q=has_role&unscoped_q=has_role
[4]: https://stackoverflow.com/a/16096790/1511504
[5]: /backend/resource-admin
