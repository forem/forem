---
title: Tracking
---

## Visits & Events

For first-party analytics, we use the
[`ahoy_matey` gem](https://github.com/ankane/ahoy), which tracks visits and
events.

We intentionally choose to limit what user data we track and persist, and have
opted to follow the GDPR compliance standards
[set by Ahoy](https://github.com/ankane/ahoy#gdpr-compliance-1). By default, we
have configured the Ahoy library to mask IP addresses, disable geocode tracking,
and not track user cookies.

### Visits

Ahoy creates an `Ahoy::Visit` record for each visit that it tracks.

By default, we have turned off visit tracking in the `ApplicationController`:

```ruby
skip_before_action :track_ahoy_visit
```

We currently only create visits on the server-side when they are required to be
created by events. Visits can be re-enabled for specific controller actions if
necessary, but this should be done so _with explict care_.

We do not collect any personal user data when tracking visits. Our collected
data is limited to the user's `id`. Each user has a unique `visitor_token`,
while each visit to the site is marked with a unique `visit_token`.

### Events

Ahoy creates an `Ahoy::Event` record for each event that it tracks. If no visit
is recorded for a user when an event is tracked, Ahoy will simultaneously create
an `Ahoy::Visit` for the event being tracked.

Events can be tracked in a controller action on the backend, or with JavaScript
on the frontend. Learn more about tracking events with JavaScript in our
[frontend tracking guide](/frontend/tracking).

When an event is tracked, it should include a `name` and a `properties` hash.
When adding new events, be sure that the name is unique per-event. The
properties will help you differentiate between events.

In order to track a specific event in a controller, use the `ahoy.track` call:

```ruby
class YourController < ApplicationController
  after_action :track_my_action

  protected

  def track_my_action
    ahoy.track "A specific description of your event", request.path_parameters
  end
end
```

Event tracking can be enabled for specific controller actions, but should be
done so _with explict care_.

## Messages

For email analytics, we use the
[`ahoy_messages` gem](https://github.com/ankane/ahoy_email), which tracks a
history of email messages sent to users.

Ahoy creates an `Ahoy::Message` record for each email sent by default, but can
be disabled on a per-mailer basis.
