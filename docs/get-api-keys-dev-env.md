There are a few services you'll need **_(all free)_** in order to run the development server and access the app locally. Here are the instructions for getting them:

# Algolia

Aloglia is bla bla bla

## Algolia: Sign up

1. Go to Algolia singing up [page](https://www.algolia.com/apps/AJVD3Q9KL3/dashboard).

2. Choose one of the three methods of signing up. (email, github or google)

3. Fill in your basic information.

4. Select the datacenter's region.

5. Fill in or skip the project information.

6. You are all set up now! You can go to your dashboard.

7. You can skip the tutorial, we will guide you through the process. Accept the [Terms and Conditions](https://www.algolia.com/policies/terms).

8. All good! You can get your API keys now.

## Algolia: Get API keys

1. [Sign up](#algolia-sign-up) or [Sign in](https://www.algolia.com/users/sign_in) in your Algolia account.

2. From your **Dashboard** click on **API Keys**.

3. Change your keys accordingly (name of Algolia key -> name of our `ENV` variable):
   ```
   Application ID -> ALGOLIASEARCH_APPLICATION_ID
   Search-Only API Key -> ALGOLIASEARCH_SEARCH_ONLY_KEY
   Admin API KEY -> ALGOLIASEARCH_API_KEY
   ```
4. Done.

# Twitter App

## Sign up

1. [Sign in](https://developer.twitter.com/apps) your Twitter account.

2. In order to get the API keys you will have to apply for a developer account. Click on **Apply** buttons.

3. Setup your Twitter account. Be sure you have your phone number and email address filled in.

4. Fill in your account information and give a name to your **developer account**.

5. Write down the reasons that you want to use Twitter API. Mention DEV community and describe the issues and tests and things that you want you want to work on.

6. Read :) and accept the Terms and Conditions.

7. Verify your email address once more and you will be done.

8. You are done.

---

1.  [Click this link and sign in/sign up for a Twitter account.](https://apps.twitter.com) Note that your Twitter account will need a phone number linked to it in order to create an app.
2.  Create a new app, and fill out the form, like the following example image: ![](https://user-images.githubusercontent.com/17884966/41612665-952d4cae-73c1-11e8-8047-cf0bd03bffb6.png)

The only important field is the "Callback URL" `http://localhost:3000/users/auth/twitter/callback`, which redirects you properly to `localhost:3000` when signing in.

3.  Once done, go to your app's settings, and fill in the terms of service `http://dev.to/terms` and privacy policy URL `http://dev.to/privacy`:

![](https://user-images.githubusercontent.com/17884966/41617044-8155387a-73cd-11e8-9e1d-f14c4652bda2.png)

4.  Once done, go to your app's permissions, and check the "Request email addresses from users" box.
    ![screen shot 2018-05-02 at 5 02 48 pm](https://user-images.githubusercontent.com/17884966/39549184-f2e19952-4e2a-11e8-81ad-10e06c4e8a61.png)

5.  Change your keys accordingly: (name of Twitter key -> name of our application key):

```
Access Token -> TWITTER_KEY
Access Token Secret -> TWITTER_SECRET
```

6.  Done!

# GitHub

1.  [Click this link and sign in/sign up for a GitHub account.](https://github.com/settings/applications/new)
2.  Once signed in, create a new OAuth app. Here's an example; the URLs must match the example:
    ![screen shot 2018-04-26 at 4 08 01 pm](https://user-images.githubusercontent.com/17884966/39329488-77cbf554-496c-11e8-941e-dd257b5223ee.png)
3.  Change your keys accordingly; (name of GitHub key -> name of our application key):

```
Client ID -> GITHUB_KEY
Client Secret -> GITHUB_SECRET
```

4.  Done!

# Pusher

1. [Sign up for a free account with this link](https://dashboard.pusher.com/accounts/sign_up).

   ![screen shot 2018-10-03 at 5 48 09 pm](https://user-images.githubusercontent.com/7942714/46447013-85187700-c734-11e8-92f7-89a17240ea0f.png)

2. Once signed in, fill out the prompt to create a new Pusher Channels app. Only an app name is required.

   ![screen shot 2018-10-03 at 5 35 14 pm](https://user-images.githubusercontent.com/7942714/46446837-69f93780-c733-11e8-82d9-52ad97812d4b.png)

3. In your new Pusher Channels app, click the "App Keys" tab.

   ![screen shot 2018-10-03 at 5 41 43 pm](https://user-images.githubusercontent.com/7942714/46446905-c0667600-c733-11e8-9c55-8fabf28a27fe.png)

4. Change your keys accordingly (name of Pusher key -> name of our application key):

```
app_id -> PUSHER_APP_ID
key -> PUSHER_KEY
secret -> PUSHER_SECRET
cluster -> PUSHER_CLUSTER
```

5. Done!
