---
title: Commandeering Users
---

#  Commandeering Users

During development, it will inevitably become necessary to control multiple users.

Obviously, you shouldn't create an infinite amout of GitHub or Twitter accounts to generate test users (seriously, please don't do this).

Instead, you can take advantage of a small hack that is exposed when the application runs in development mode. There is a gem in the lib directory called [quickin](https://github.com/thepracticaldev/dev.to/pull/3893), which exists to solve this problem for Dev.to contributors.

The quickin gem exposes the `/quickin` route, which will allow you to grab a currently existing user and skip the authentication process. For obvious reasons, this route is not exposed when the application runs in production.

To log in as the first user in the database, all you have to do is navigate to `localhost:3000/quickin`. You can also specify which user you'd like to take over by including the user's `id` as a parameter:

```
# Login as the user with an id of 4
localhost:3000/quickin?id=4
```

Please be careful with this functionality; it's pretty hacky. As every Tobey Maguire fan knows, "With great power comes great responsibility."
