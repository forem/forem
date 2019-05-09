---
title: Authorization
---

# Authorization

Authorization is handled by the third party gem [Pundit](https://github.com/varvet/pundit) through the `authorize` method which you can find in various controllers, look for statements like:

```ruby
authorize @user
```

All authorization policies can be found in `/app/policies`.
