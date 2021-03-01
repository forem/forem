---
title: Audit Log
---

# Audit Log

To help maintain accountability for users with elevated permissions the Forem
application has a special model that records certain actions.

For example, when a user with the `trusted` role creates a negative reaction on
an article a record is created with certain information about that action.

That record (which we call an `AuditLog`) looks something like this:

```ruby
#<AuditLog:0x00005629f019a490
 id: 1,
 category: "moderator.audit.log",
 created_at: Thu, 07 May 2020 20:25:31 UTC +00:00,
 data:
  {"action"=>"create", "category"=>"vomit", "controller"=>"reactions", "reactable_id"=>"16", "reactable_type"=>"Article"},
 roles: ["trusted"],
 slug: "create",
 updated_at: Thu, 07 May 2020 20:25:31 UTC +00:00,
 user_id: 21>
```

You can see from this record that the user with an id of `21` created a vomit
reaction on the article with an id of `16`. If that's not obvious to you from
this object, don't worry, just take our word on it.

You can find an example of `Audit::Logger` in action in
`app/controllers/admin/reactions_controller.rb`:

```ruby
  after_action only: [:update] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end
```

This code creates a record to indicate that a someone modified a reaction from
the admin controller.

It's a good idea to add a similar `after_action` to any controller action that
might benefit from increased transparency.

Additionally, the `AuditLog` is used to track important actions performed on a
user's account, e.g. adding or removing a credit card:

```ruby
#<AuditLog:0x00000001193ce348> {
    category: "user.credit_card.edit",
  created_at: Tue, 21 Jul 2020 06:35:13 +03 +03:00,
        data: {
         "action" => "create",
     "controller" => "stripe_active_cards",
    "user_action" => "add"
  },
          id: 4,
       roles: [],
        slug: "credit_card_add",
  updated_at: Tue, 21 Jul 2020 06:35:13 +03 +03:00,
     user_id: 53
}
```
