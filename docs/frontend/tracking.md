---
title: Tracking
---

## Ahoy.js

For first-party analytics, we use the
[`ahoy.js` library](https://github.com/ankane/ahoy.js), which tracks visits and
events. This library works in conjunction with the `ahoy_matey` gem, which is
documented in our [backend tracking guide](/backend/tracking).

### Configuration

The configuration for `ahoy.js` lives in `app/assets/javascripts/base.js.erb`.
Since we do not track user cookies on the backend, we have configured
`ahoy.js`'s defaults to match that on the frontend.

### Events

In order to track an event, use the `ahoy.track` function:

```javascript
ahoy.track(name, properties);
```

This function will send a `POST` request to the `/ahoy/events` endpoint on our
backend with the `name` and `properties` of the event. The backend endpoint will
also create a corresponding `Ahoy::Visit` for the event if one does not exist
already.
