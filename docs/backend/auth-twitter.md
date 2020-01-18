---
title: Twitter Authentication
---

# Twitter App and Authentication

DEV allows you to authenticate using Twitter. In order to use this
authentication method in local development, you will need to setup a Twitter App
and retrieve its keys. Then you'll need to provide these keys to the Rails
application.

## Sign up

1. [Sign in](https://developer.twitter.com/apps) to your Twitter account.

2. In order to get the API keys, you will have to
   [apply for a developer account](https://developer.twitter.com/en/apply-for-access).
   Click the **Apply** button.

   ![twitter-up-1](https://user-images.githubusercontent.com/22895284/51078779-53139b00-16bb-11e9-911c-f232e229872a.png)

3. Setup your Twitter account. Be sure you have your phone number and email
   address filled in.

   ![twitter-up-2](https://user-images.githubusercontent.com/22895284/51078780-53139b00-16bb-11e9-91d5-08c9365ff08f.png)

4. Fill in your account information and give a name to your **developer
   account**.

   ![twitter-up-3](https://user-images.githubusercontent.com/22895284/51078781-53ac3180-16bb-11e9-8cf4-005efbb92d8a.png)

5. Write down the reasons that you want to use Twitter API. Mention DEV's
   community and describe the issues and tests and things that you want to work
   on. Copy it, you might use it later ;)

   ![twitter-up-4](https://user-images.githubusercontent.com/22895284/51078782-53ac3180-16bb-11e9-9937-c888ae40143c.png)

6. Read :) and accept the Terms and Conditions.

   ![twitter-up-5](https://user-images.githubusercontent.com/22895284/51078783-53ac3180-16bb-11e9-9cf1-8e009ada6e57.png)

7. Verify your email address once more, and you will be done.

8. You are done.

## Get API keys

1. [Sign up](#twitter-sign-up) or [sign in](https://developer.twitter.com/apps)
   to your Twitter developer account.

2. From **Apps** dashboard, click on **Create and app**.

   ![twitter-1](https://user-images.githubusercontent.com/22895284/51078797-9a019080-16bb-11e9-8130-1cd13008461e.png)

3. Fill in the app name, description, and URL `https://dev.to`.

   ![twitter-2](https://user-images.githubusercontent.com/22895284/51078798-9a019080-16bb-11e9-900d-d2677d7c43c4.png)

4. Check the **Enable Sign in with Twitter** option and fill in the Callback URL
   `http://localhost:3000/users/auth/twitter/callback` (or whatever port you run
   DEV on).

   ![twitter-3](https://user-images.githubusercontent.com/22895284/51078799-9a9a2700-16bb-11e9-8e88-0393260449c7.png)

5. Fill in the DEV information, **Terms of Service** `http://dev.to/terms` and
   **Privacy policy** `http://dev.to/privacy`.

   ![twitter-4](https://user-images.githubusercontent.com/22895284/51078800-9a9a2700-16bb-11e9-9b36-d325a2624f5a.png)

6. Write down (or paste) the things that you will work on. Press **Create**.

   ![twitter-5](https://user-images.githubusercontent.com/22895284/51078801-9a9a2700-16bb-11e9-9bd9-76c9ca1ba526.png)

7. Review the
   [Twitter Developer Terms](https://developer.twitter.com/en/developer-terms/agreement-and-policy.html)
   and agree to do nothing sketchy.

   ![twitter-6](https://user-images.githubusercontent.com/22895284/51078802-9a9a2700-16bb-11e9-8789-53720bcfc9d9.png)

8. The app is all set!

9. One more change: From the app dashboard, go to **Permissions** and check
   **Request email addresses from users** option.

   ![twitter-7](https://user-images.githubusercontent.com/22895284/51078803-9a9a2700-16bb-11e9-8f27-dbfe04b52031.png)

10. From the same dashboard access the **Keys and tokens** and change them
    accordingly (name of Twitter key -> name of our `ENV` variable). Be sure to
    copy the _access token_ and _access token secret_ right away because it will
    be hidden from you in the future.

    ```text
    API key -> TWITTER_KEY
    API secret key -> TWITTER_SECRET
    ```

    ![twitter-8](https://user-images.githubusercontent.com/47985/72329507-72d30a00-36e7-11ea-83ac-ebea5d41ba39.png)
