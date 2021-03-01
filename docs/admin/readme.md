---
title: Admin Guide
items:
  - admin-search.md
  - internal-user-interface.md
---

# Admin Guide

The Forem application contains a rudimentary administration dashboard that lives
behind the admin route.

The admin dashboard is made up of a series of views that range from
administration tools to simplified reports. These tools are used by users with
the `admin` or `super_admin` roles to administrate the Forem application.

Authorization for these tools is handled by the [Rolify][rolify] gem.

Currently, a workaround exists to give access to certain `admin` views via
Rolify by assigning the role `single_resource_admin` to a user.

`single_resource_admin` users are given access to a Ruby class. In the codebase,
there are admin models, not backed by database tables, that exist for this
purpose. For example, if you needed to give a user access to only
`/admin/welcome`, you'd run the following command in the Rails console:

```ruby
user = User.find(some_user_id)
user.add_role(:single_resource_admin, Welcome)
```

This gives the user administration privileges on the controller associated with
an almost empty Rails model that lives in `app/models/admin/welcome.rb`:

```ruby
class Welcome < ApplicationRecord
  resourcify
  # This class exists to take advantage of Rolify for limiting authorization
  # on admin reports.
  # NOTE: It is not backed by a database table and should not be expected to
  # function like a traditional Rails model
end
```

Now that user will be able to access the view at `admin/welcome`. The same
workaround has been implemented for most of the admin views.

[rolify]: https://github.com/RolifyCommunity/rolify
