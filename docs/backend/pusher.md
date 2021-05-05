---
title: Pusher
---

# Pusher for Realtime Notifications

Pusher is a third party service being used to power the
[chat system](https://dev.to/connect) and Push Notifications on
[iOS](https://apps.apple.com/us/app/dev-community/id1439094790) &
[Android](https://play.google.com/store/apps/details?id=to.dev.dev_android)
native apps.

## Chat System

In order to use the chat functionality within your development environment, you
will need to sign up for a free-tier Pusher account and retrieve its keys. Then
you'll need to provide those keys to the Rails application.

1. [Sign up](https://dashboard.pusher.com/accounts/sign_up) or
   [sign in](https://dashboard.pusher.com/) to your Pusher account.

2. Once signed in, fill in the prompt to create a new Pusher Channels app.

   ![pusher-1](https://user-images.githubusercontent.com/22895284/51086056-058e4100-1742-11e9-8dca-de3e47e2bc73.png)

3. In your new Pusher Channels app, click the "App Keys" tab.

   ![pusher-2](https://user-images.githubusercontent.com/22895284/51086057-058e4100-1742-11e9-9fb7-397187aa8689.png)

4. Change your keys accordingly (name of Pusher key -> name of our application
   key):

   ```text
   app_id -> PUSHER_APP_ID
   key -> PUSHER_KEY
   secret -> PUSHER_SECRET
   cluster -> PUSHER_CLUSTER
   ```

   ![pusher-3](https://user-images.githubusercontent.com/22895284/51086058-0626d780-1742-11e9-9c2a-26b9b10fa77f.png)

5. Done.
