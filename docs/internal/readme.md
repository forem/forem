---
title: Internal Guide
items:
  - internal-search.md
  - internal-user-interface.md
---

# Internal Guide

The DEV application contains a rudimentary administration dashboard that lives
behind the internal route.

The internal dashboard is made up of a series of views that range from
administration tools to simplified reports. These tools are used by users with
the `admin` or `super_admin` roles to administrate the DEV application.

Authorization for these tools is handled by the [Rolify][rolify] gem.

Currently, a workaround exists to give access to certain `internal` views via
Rolify by assigning the role `single_resource_admin` to a user.

`single_resource_admin` users are given access to a Ruby class. In the codebase,
there are internal models, not backed by database tables, that exist for this
purpose. For example, if you needed to give a user access to only
`/internal/welcome`, you'd run the following command in the Rails console:

```ruby
user = User.find(some_user_id)
user.add_role :single_resource_admin, Welcome
```

This gives the user administration privileges on the controller associated with
an almost empty Rails model that lives in `app/models/internal/welcome.rb`:

```ruby
class Welcome < ApplicationRecord
  resourcify
  # This class exists to take advantage of Rolify for limiting authorization
  # on internal reports.
  # NOTE: It is not backed by a database table and should not be expected to
  # function like a traditional Rails model
end
```

Now that user will be able to access the view at `internal/welcome`. The same
workaround has been implemented for most of the internal views.

[rolify]: https://github.com/RolifyCommunity/rolify
