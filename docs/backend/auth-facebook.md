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

   ![facebook-1](https://user-images.githubusercontent.com/37842/90912963-1f254f00-e3a1-11ea-9db9-2b77bddfe185.png)

3. Select **For Everything Else**

   ![facebook-2](https://user-images.githubusercontent.com/37842/90913109-627fbd80-e3a1-11ea-8d78-d0b2bde76b3d.png)

4. Fill in the app display name and contact email, then click on **Create App
   ID**

   ![facebook-3](https://user-images.githubusercontent.com/37842/90913171-7b886e80-e3a1-11ea-9359-c4642c05c7b6.png)

5. On the **Add a Product** screen, click **Set Up** under the **Facebook
   Login** section

   ![facebook-4](https://user-images.githubusercontent.com/37842/90913219-8d6a1180-e3a1-11ea-86cb-d0b0d8681887.png)

6. Ignore the quickstart options, and click **Settings -> Basic** in the sidebar

   ![facebook-5](https://user-images.githubusercontent.com/37842/90913319-b5f20b80-e3a1-11ea-866a-0b06cf3296c7.png)

7. From the basic settings screen dashboard copy the **App ID** and **App
   Secret** values to your `.env` file accordingly (name of Facebook key -> name
   of our `Settings::General` variable).

   ```text
   APP ID -> FACEBOOK_APP_ID
   API secret -> FACEBOOK_APP_SECRET
   ```

   ![facebook-6](https://user-images.githubusercontent.com/37842/90913396-d5893400-e3a1-11ea-93f5-a0fbb06a0c53.png)

## Configure the Facebook App

1. From the basic settings screen dashboard set your application's domain name
   in **App Domains** field, and be sure to click **Save Changes**

   ![facebook-7](https://user-images.githubusercontent.com/37842/91494838-20fa8100-e87f-11ea-8609-0d3b92edc093.png)

2. Naviate to **Facebook Login --> Settings**, and enter the following callback
   URL in the field **Valid OAuth Redirect URIs**:

   `https://<your domain>>/users/auth/facebook/callback`

   ![facebook-8](https://user-images.githubusercontent.com/37842/91509964-48624580-e8a1-11ea-9f7b-931cfcb7cd87.png)
