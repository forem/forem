---
title: Authorization
---

# Authorization

Authorization is handled by the third party gem [pundit](https://github.com/varvet/pundit).

The policies can be found in `/app/policies`

Authorization is handled by the `authorize` method which you will find in various controllers

```rb
  authorize @user
```
