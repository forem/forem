---
title: Push Notifications
---

# Push Notifications Delivery

Forem instances rely on [Rpush](https://github.com/rpush/rpush) to deliver push
notifications. This decision was heavily influenced by the desire to
provide as much flexibility as possible to Creators. In order to do this, Forem
instances can register and configure a `ConsumerApp`.

These consumer apps represent mobile applications that users use to browse and consume content
on a Forem. Authenticated users of a specific Forem instance can register a `Device`
associated to a `ConsumerApp`. With these pieces we are able to deliver
push notifications to users devices.

The `ConsumerApp` configuration page can be found at
`/admin/apps/consumer_apps`. The official Forem apps are supported by default
and require their secret credential to be provided via ENV variable.

## Rpush Implementation

We use Rpush's `rpush-redis` implementation (read
[this thread](https://github.com/forem/forem/pull/12419/files#r564660917) for
the reasons why), hence all `Rpush` models are persisted in Redis. More
details about how this works
[here](https://github.com/rpush/rpush/wiki/Using-Redis).
