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

## Mobile Push Notifications

These steps are required only when working with the native Apps. In order to
setup Push Notifications to mobile devices you need to create a Pusher Beams
instance and retrieve its credentials

1. [Sign up](https://dashboard.pusher.com/accounts/sign_up) or
   [sign in](https://dashboard.pusher.com/) to your Pusher account.

2. Once signed in, go in the "BEAMS" section on the left sidebar and fill in the
   prompt to create a new Pusher Beams instance.

![pusher-beams-1](https://user-images.githubusercontent.com/6045239/78602158-2e9d6480-7813-11ea-9da1-4f1310776570.png)

3. In your new Pusher Beams instance, click the "Credentials" tab.

   ![pusher-beams-2](https://user-images.githubusercontent.com/6045239/78602934-82f51400-7814-11ea-8cc8-6933c43079bc.png)

4. Change your keys accordingly (name of Pusher key -> name of our application
   key):

```text
Instance ID -> PUSHER_BEAMS_ID
Instance Key -> PUSHER_BEAMS_KEY
```

5. Done. You now have your server configured to use Pusher Beams.

However, in order to send Push Notifications to devices you'll need to do some
platform specific configuration as well.

### Firebase for Android Push Notifications

1. Sign up or Sign in to [Firebase](https://firebase.google.com/)

2. Add a new project. Google Analytics doesn't need to be configured for this
   Push Notifications to work.

![fcm-1](https://user-images.githubusercontent.com/6045239/78604287-cfd9ea00-7816-11ea-9b47-b374b4e60faf.png)

![fcm-2](https://user-images.githubusercontent.com/6045239/78609833-d2d9d800-7820-11ea-9d78-53dfe823bd3f.png)

3. Add Android support for your iOS app

![fcm-3](https://user-images.githubusercontent.com/6045239/78609955-1b919100-7821-11ea-8a2f-9f96cf26185c.png)

![fcm-4](https://user-images.githubusercontent.com/6045239/78612418-885b5a00-7826-11ea-91b8-125981367068.png)

4. Download the `google-services.json` file (to be used in the Android app)

![fcm-5](https://user-images.githubusercontent.com/6045239/78612412-85f90000-7826-11ea-8996-dcb568e7b037.png)

5. Finish off the next steps (not required at this moment). Now head over to
   your Firebase project's settings page and copy the Server key from the "Cloud
   Messaging" tab

![fcm-6](https://user-images.githubusercontent.com/6045239/78615948-11c35a00-7830-11ea-8470-675488a0ecc1.png)

6. Now back in your Pusher Beams page account add the Server key from the
   previous step under the "Settings" tab

![fcm-7](https://user-images.githubusercontent.com/6045239/78616350-353ad480-7831-11ea-8d63-2f183c2f233b.png)

7. Done.
