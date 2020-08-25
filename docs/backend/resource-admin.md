---
title: Resource Admin Panel
---

# What is the resource admin panel?

The resource admin panel is a CRUD interface generated via the
[Administrate gem](https://github.com/thoughtbot/administrate). In production,
this is generally not used often and will be deprecated in favor of the admin
panel (`http://localhost:3000/admin/*`). For more details, see
[the admin guide](/admin).

# Accessing the resource admin panel

There is an resource admin panel located at
<http://localhost:3000/resource_admin>.

To access the panel, you must be logged with a user with the `admin` role
activated.

To activate such a role, you can follow these instructions:

- open the Rails console

```shell
rails console
```

1. load the user object of for _bob_ (or whatever the username is)

```ruby
Loading development environment (Rails 6.0.3)
[1] pry(main)> user = User.find_by(username: "bob")
[2] pry(main)> user.add_role(:super_admin)
[3] pry(main)> user.save!
```

Now you'll be able to access the
[resource administration panel](http://localhost:3000/resource_admin).
