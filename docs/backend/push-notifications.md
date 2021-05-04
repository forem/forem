---
title: Push Notifications
---

# Push Notification (PN) Delivery

Forem instances rely on [Rpush](https://github.com/rpush/rpush) to deliver Push
Notifications (PN's). This decision was heavily influenced by the intention to
provide as much flexibility as possible to Creators. In order to do this Forem
instances can register & configure a `ConsumerApp`.

These apps represent (mobile) apps that users use to consume the Forem instance.
Registered users of Forem instances can register a `Device` associated to a
`ConsumerApp`. With these three pieces we are able to deliver a PN to a user's
registered physical device(s).

The `ConsumerApp` configuration page can be found at
`/admin/apps/consumer_apps`. The official Forem apps are supported by default
and require their secret credential to be provided via ENV variable.

## Rpush Implementation

We use Rpush's `rpush-redis` implementation (read
[this thread](https://github.com/forem/forem/pull/12419/files#r564660917) for
the reasons why), and this means **we don't rely on Postgres** for all of Rpush
functionality. All Rpush models are persisted in Redis. More details about how
this works can be found [here](https://github.com/rpush/rpush/wiki/Using-Redis).
