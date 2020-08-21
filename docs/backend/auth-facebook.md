---
title: Facebook Authentication
---

# Facebook App and Authentication

Forem allows you to authenticate using Facebook. In order to use this
authentication method in local development, you will need to setup a Facebook
App and retrieve its keys. Then you'll need to provide these keys to the Rails
application.

## Sign up

1. [Sign in](https://facebook.com) to your Facebook account.

2. In order to get the API keys, you will have to
   [convert your account to a developer account](https://developers.facebook.com/).

## Get API keys

1. [Sign up](#facebook-sign-up) or [sign in](https://developers.facebook.com) to
   your Facebook developer account.

2. From **My Apps** dashboard, click on **Add a New App**.

   ![facebook-1]()

3. Select **For Everything Else**

![facebook-2]()

4. Fill in the app display name and contact email, then click on **Create App
   ID**

![facebook-3]()

5. On the **Add a Product** screen, click **Set Up** under the **Facebook
   Login** section

![facebook-4]()

6. On the quickstart option screen, select **Other**, then select **Manually
   Build a Login Flow**

![facebook-5]()

7. Ignore the quickstart options, and click **Settings -> Basic** in the sidebar

![facebook-6]()

8. From the basic settings screen dashboard copy the **App ID** and **App
   Secret** values to your environment settings accordingly (name of Facebook
   key -> name of our `ENV` variable).

   ```text
   APP ID -> FACEBOOK_APP_ID
   API secret -> FACEBOOK_APP_SECRET
   ```

   ![twitter-7]()
