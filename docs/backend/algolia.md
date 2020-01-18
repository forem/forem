---
title: Algolia
---

## Algolia for Search

Algolia is a third party service that powers the search. When working with the
API, you will likely need to utilize Algolia. You will need to sign up for a
free-tier account, retrieve the keys, and provide those keys to the Rails
application.

## Sign up

1. Go to the Algolia sign up [page](https://www.algolia.com/users/sign_up).

2. Choose one of the three methods of signing up: email, GitHub, or Google.

3. Fill in your information.

   ![algolia-up-1](https://user-images.githubusercontent.com/22895284/51078744-ad602c00-16ba-11e9-9f59-7f9f2cc0443f.png)

4. Select the datacenter's region.

   ![algolia-up-2](https://user-images.githubusercontent.com/22895284/51078745-ad602c00-16ba-11e9-81ee-6ec3310919d9.png)

5. Fill in or skip the project information.

   ![algolia-up-3](https://user-images.githubusercontent.com/22895284/51078746-ad602c00-16ba-11e9-9927-d790ce03761e.png)

6. You are all set up now! You can go to your dashboard.

   ![algolia-up-4](https://user-images.githubusercontent.com/22895284/51078747-ad602c00-16ba-11e9-8654-67c4d0f2e651.png)

7. You can skip the tutorial, by clicking on API button.

   ![algolia-up-5](https://user-images.githubusercontent.com/51912296/63767468-5f1b3880-c8eb-11e9-88c3-7b14774b684d.png)

8. All good! You can get your API keys now.

## Get API keys

1. [Sign up](#algolia-sign-up) or
   [Sign in](https://www.algolia.com/users/sign_in) to your Algolia account.

2. From your **Dashboard**, click on **API Keys**.

   ![algolia-1](https://user-images.githubusercontent.com/22895284/51078770-2eb7be80-16bb-11e9-9dcc-ed6d9c52d935.png)

3. Change your keys accordingly (name of Algolia key -> name of our `ENV`
   variable):

   ```text
   Application ID -> ALGOLIASEARCH_APPLICATION_ID
   Search-Only API Key -> ALGOLIASEARCH_SEARCH_ONLY_KEY
   Admin API KEY -> ALGOLIASEARCH_API_KEY
   ```

   ![algolia-2](https://user-images.githubusercontent.com/22895284/51078771-2eb7be80-16bb-11e9-9622-f19417f1b29c.png)

4. Done.

## Notes

Algolia puts you on a trial account by defult. The trial period is 14 days. But
don't worry, it also offers a free plan called **Community**. You may want to
switch to it manually:

1. Go to [Billing](https://www.algolia.com/billing) section.

   ![algolia-community-plan-1](https://user-images.githubusercontent.com/108287/72377741-f866b200-3707-11ea-974f-591f965f05b4.png)

2. Choose **Community** plan and submit.

   ![algolia-community-plan-2](https://user-images.githubusercontent.com/108287/72377900-3cf24d80-3708-11ea-8371-43563ca7fb43.png)

3. Done.
