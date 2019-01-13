There are a few services you'll need **_(all free)_** in order to run the development server and access the app locally. Here are the instructions for getting them.

# GitHub

1. [Sign in](https://github.com/settings/applications/new) in your Github account.

2. Fill in the form with and application name, descriptions and URLs `http://localhost:3000/`. Replace the `3000` port if you run DEV on other port.
   ![github-1](https://user-images.githubusercontent.com/22895284/51085500-877a6c00-173a-11e9-913a-0dccad234cf3.png)

3. You will be redirected in app's **Developer settings**. Here you will find the keys. Change them accordingly (name of Github key -> name of our `ENV` variable):

   ```
   Client ID -> GITHUB_KEY
   Client Secret -> GITHUB_SECRET
   ```

   ![github-2](https://user-images.githubusercontent.com/22895284/51085862-49337b80-173f-11e9-8503-f8251d07f458.png)

4. You will need a persona token as well. From the same dashboard navigate to **Personal access tokens** and generate a new token.
   ![github-3](https://user-images.githubusercontent.com/22895284/51085863-49337b80-173f-11e9-81bf-1c1e38035a7a.png)
5. Fill in the token description and generate the token.

6. Be sure that you copy the token right away, because it is the only time you will see it. Change it accordingly.

   ```
   Personal access tokens -> GITHUB_TOKEN
   ```

   ![github-4](https://user-images.githubusercontent.com/22895284/51085865-49cc1200-173f-11e9-86a8-7e7e1db408a0.png)

7. Done.

# Twitter App

## Twitter: Sign up

1. [Sign in](https://developer.twitter.com/apps) your Twitter account.

2. In order to get the API keys you will have to apply for a developer account. Click on **Apply** buttons.
   ![twitter-up-1](https://user-images.githubusercontent.com/22895284/51078779-53139b00-16bb-11e9-911c-f232e229872a.png)

3. Setup your Twitter account. Be sure you have your phone number and email address filled in.
   ![twitter-up-2](https://user-images.githubusercontent.com/22895284/51078780-53139b00-16bb-11e9-91d5-08c9365ff08f.png)

4. Fill in your account information and give a name to your **developer account**.
   ![twitter-up-3](https://user-images.githubusercontent.com/22895284/51078781-53ac3180-16bb-11e9-8cf4-005efbb92d8a.png)

5. Write down the reasons that you want to use Twitter API. Mention DEV community and describe the issues and tests and things that you want you want to work on. Copy it, you might use it later ;)
   ![twitter-up-4](https://user-images.githubusercontent.com/22895284/51078782-53ac3180-16bb-11e9-9937-c888ae40143c.png)

6. Read :) and accept the Terms and Conditions.
   ![twitter-up-5](https://user-images.githubusercontent.com/22895284/51078783-53ac3180-16bb-11e9-9cf1-8e009ada6e57.png)

7. Verify your email address once more and you will be done.

8. You are done.

## Twitter: Get API keys

1. [Sign up](#twitter-sign-up) or [sign in](https://developer.twitter.com/apps) in your Twitter developer account.

2. From **Apps** dashboard click on **Create and app**.
   ![twitter-1](https://user-images.githubusercontent.com/22895284/51078797-9a019080-16bb-11e9-8130-1cd13008461e.png)

3. Fill in the app name, description and URL `https://dev.to`.
   ![twitter-2](https://user-images.githubusercontent.com/22895284/51078798-9a019080-16bb-11e9-900d-d2677d7c43c4.png)

4. Check the **Enable Sign in with Twitter** option and fill in the Callback URL `http://localhost:3000/users/auth/twitter/callback` (or whatever port you run DEV on).
   ![twitter-3](https://user-images.githubusercontent.com/22895284/51078799-9a9a2700-16bb-11e9-8e88-0393260449c7.png)
5. Fill in the DEV information, **Terms of Service** `http://dev.to/terms` and **Privacy policy** `http://dev.to/privacy`.
   ![twitter-4](https://user-images.githubusercontent.com/22895284/51078800-9a9a2700-16bb-11e9-9b36-d325a2624f5a.png)

6. Write down (or paste) the things that you will work on. Press **Create**.
   ![twitter-5](https://user-images.githubusercontent.com/22895284/51078801-9a9a2700-16bb-11e9-9bd9-76c9ca1ba526.png)

7. Review the [Twitter Developer Terms](https://developer.twitter.com/en/developer-terms/agreement-and-policy.html) and agree to do nothing sketchy.
   ![twitter-6](https://user-images.githubusercontent.com/22895284/51078802-9a9a2700-16bb-11e9-8789-53720bcfc9d9.png)

8. The app is all set!

9. One more change... From the app dashboard go to **Permissions** and check **Request email addresses from users** option.
   ![twitter-7](https://user-images.githubusercontent.com/22895284/51078803-9a9a2700-16bb-11e9-8f27-dbfe04b52031.png)

10. From the same dashboard access the **Keys and tokens** and change them accordingly (name of Twitter key -> name of our `ENV` variable):

    ```
    Access Token -> TWITTER_KEY
    Access Token Secret -> TWITTER_SECRET
    API key -> TWITTER_ACCESS_TOKEN
    API secret key -> TWITTER_ACCESS_TOKEN_SECRET
    ```

    ![twitter-8](https://user-images.githubusercontent.com/22895284/51078804-9a9a2700-16bb-11e9-8b9e-0c882ae47f21.png)

11. Done.

# Algolia

## Algolia: Sign up

1. Go to Algolia singing up [page](https://www.algolia.com/apps/AJVD3Q9KL3/dashboard).

2. Choose one of the three methods of signing up. (email, github or google)

3. Fill in your information.
   ![algolia-up-1](https://user-images.githubusercontent.com/22895284/51078744-ad602c00-16ba-11e9-9f59-7f9f2cc0443f.png)

4. Select the datacenter's region.
   ![algolia-up-2](https://user-images.githubusercontent.com/22895284/51078745-ad602c00-16ba-11e9-81ee-6ec3310919d9.png)

5. Fill in or skip the project information.
   ![algolia-up-3](https://user-images.githubusercontent.com/22895284/51078746-ad602c00-16ba-11e9-9927-d790ce03761e.png)

6. You are all set up now! You can go to your dashboard.
   ![algolia-up-4](https://user-images.githubusercontent.com/22895284/51078747-ad602c00-16ba-11e9-8654-67c4d0f2e651.png)

7. You can skip the tutorial, we will guide you through the process. Accept the [Terms and Conditions](https://www.algolia.com/policies/terms).
   ![algolia-up-5](https://user-images.githubusercontent.com/22895284/51078748-ad602c00-16ba-11e9-8ff6-6becac2152ac.png)

8. All good! You can get your API keys now.

## Algolia: Get API keys

1. [Sign up](#algolia-sign-up) or [Sign in](https://www.algolia.com/users/sign_in) in your Algolia account.

2. From your **Dashboard** click on **API Keys**.
   ![algolia-1](https://user-images.githubusercontent.com/22895284/51078770-2eb7be80-16bb-11e9-9dcc-ed6d9c52d935.png)

3. Change your keys accordingly (name of Algolia key -> name of our `ENV` variable):

   ```
   Application ID -> ALGOLIASEARCH_APPLICATION_ID
   Search-Only API Key -> ALGOLIASEARCH_SEARCH_ONLY_KEY
   Admin API KEY -> ALGOLIASEARCH_API_KEY
   ```

   ![algolia-2](https://user-images.githubusercontent.com/22895284/51078771-2eb7be80-16bb-11e9-9622-f19417f1b29c.png)

4. Done.

# Pusher

1. [Sign up](https://dashboard.pusher.com/accounts/sign_up) or [sign in](https://dashboard.pusher.com/) in your Pusher account.

2. Once signed in, fill in the prompt to create a new Pusher Channels app.
   ![pusher-1](https://user-images.githubusercontent.com/22895284/51086056-058e4100-1742-11e9-8dca-de3e47e2bc73.png)

3. In your new Pusher Channels app, click the "App Keys" tab.
   ![pusher-2](https://user-images.githubusercontent.com/22895284/51086057-058e4100-1742-11e9-9fb7-397187aa8689.png)

4. Change your keys accordingly (name of Pusher key -> name of our application key):

   ```
   app_id -> PUSHER_APP_ID
   key -> PUSHER_KEY
   secret -> PUSHER_SECRET
   cluster -> PUSHER_CLUSTER
   ```

   ![pusher-3](https://user-images.githubusercontent.com/22895284/51086058-0626d780-1742-11e9-9c2a-26b9b10fa77f.png)

5. Done.
