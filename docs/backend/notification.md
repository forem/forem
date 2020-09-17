---
title: Notifications
---

# Notifications

Since notifications are run asynchronously, we'll want to make sure jobs are
running: `bundle exec sidekiq`. If that's not running, you won't receive any
notifications. You might need to create another account to pass notifications
back and forth if you're doing this all through the UI.

Otherwise, you can generate notifications from the Rails console and run the
class methods from `app/models/notification.rb`. For example:

```ruby
# follow notification
me = User.last
follow = User.first.follow(me)
Notification.send_new_follower_notification_without_delay(follow)
# reaction notification
rxn = Reaction.create(
user_id: 1,
category: "like",
reactable: me.articles.last, # this assumes you have an article written
)
Notification.send_reaction_notification_without_delay(rxn, me)
```

Notice you have to run these methods `without_delay` since this is assuming jobs
are not running.
