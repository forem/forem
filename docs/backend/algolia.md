---
title: Algolia
---

# Algolia for Search

Algolia is a third party service which powers the search. When working with the API is very likely would need to utilize Algolia. You will need to sign up for a free-tier account, retrieve the keys and provide those keys to the Rails application.

## Sign up

1. Go to the Algolia sign up [page](https://www.algolia.com/apps/AJVD3Q9KL3/dashboard).

2. Choose one of the three methods of signing up: email, github or google.

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

## Get API keys

1. [Sign up](#algolia-sign-up) or [Sign in](https://www.algolia.com/users/sign_in) to your Algolia account.

2. From your **Dashboard**, click on **API Keys**.

   ![algolia-1](https://user-images.githubusercontent.com/22895284/51078770-2eb7be80-16bb-11e9-9dcc-ed6d9c52d935.png)

3. Change your keys accordingly (name of Algolia key -> name of our `ENV` variable):

   ```text
   Application ID -> ALGOLIASEARCH_APPLICATION_ID
   Search-Only API Key -> ALGOLIASEARCH_SEARCH_ONLY_KEY
   Admin API KEY -> ALGOLIASEARCH_API_KEY
   ```

   ![algolia-2](https://user-images.githubusercontent.com/22895284/51078771-2eb7be80-16bb-11e9-9622-f19417f1b29c.png)

4. Done.
