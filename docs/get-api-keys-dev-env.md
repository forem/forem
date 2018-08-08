There are a few services you'll need **_(all free)_** in order to run the development server and access the app locally. Here are the instructions for getting them:

# Algolia (Choose OAuth or Email Sign Up)
## Algolia: OAuth Sign Up
1. [Click this link and sign up for an account with either GitHub or Google.](https://www.algolia.com/users/sign_up)
![screen shot 2018-05-02 at 3 06 05 pm](https://user-images.githubusercontent.com/17884966/39547183-c5d8b572-4e24-11e8-80e3-5b595e0c9999.png)
2. Select your region, and then hit "Let's get started!"
![screen shot 2018-05-01 at 2 30 52 pm](https://user-images.githubusercontent.com/17884966/39544263-80c7e39e-4e1b-11e8-802e-c9562bdf1b63.png)
3. Skip the tutorial (or don't) and go to your dashboard.
![screen shot 2018-05-01 at 12 59 06 pm](https://user-images.githubusercontent.com/17884966/39544344-c8cc4496-4e1b-11e8-8d81-d570a48a0668.png)
4. Click "Go to your dashboard".

![screen shot 2018-05-02 at 3 45 34 pm](https://user-images.githubusercontent.com/17884966/39547238-f4ddd1ae-4e24-11e8-942b-98a01e20c632.png)

5. Agree to Terms and Conditions.
![screen shot 2018-05-02 at 3 45 49 pm](https://user-images.githubusercontent.com/17884966/39547258-05d347fa-4e25-11e8-9335-b65c72b846af.png)

6. Click "API Keys" on the left navbar.

![screen shot 2018-05-02 at 4 24 30 pm](https://user-images.githubusercontent.com/17884966/39547400-7cdb854c-4e25-11e8-8442-7cfc1dc8bc1e.png)

7. Change your keys accordingly (name of Algolia key -> name of our application key): 
* `Application ID -> ALGOLIASEARCH_APPLICATION_ID`
* `Search-Only API Key -> ALGOLIASEARCH_SEARCH_ONLY_KEY`
* `Admin API KEY -> ALGOLIASEARCH_API_KEY`

![screen shot 2018-05-02 at 4 26 27 pm](https://user-images.githubusercontent.com/17884966/39547471-b24f2e36-4e25-11e8-9a0e-b988d6a8253f.png)

8. Done!

***
***
***

## Algolia Email Sign Up
1. [Click this link and sign up for an account with your email address.](https://www.algolia.com/users/sign_up)
![screen shot 2018-05-02 at 4 30 52 pm](https://user-images.githubusercontent.com/17884966/39547712-5ff9d338-4e26-11e8-98e9-83852021ba90.png)

2. Fill out your name and what describes you the most.
![screen shot 2018-05-01 at 12 57 03 pm](https://user-images.githubusercontent.com/17884966/39547792-9a436842-4e26-11e8-9199-c320d24476fe.png)

3. Choose your datacenter/region closest to you.
![screen shot 2018-05-01 at 12 58 36 pm](https://user-images.githubusercontent.com/17884966/39548002-3f7d2640-4e27-11e8-8701-21820d852379.png)

4. Skip the step asking about your project.
![screen shot 2018-05-01 at 12 58 12 pm](https://user-images.githubusercontent.com/17884966/39547930-09b2af08-4e27-11e8-8c1b-d6b67d75d141.png)

5. Complete the onboarding flow and click "Go to dashboard".
![screen shot 2018-05-01 at 12 58 48 pm](https://user-images.githubusercontent.com/17884966/39548519-dc0491dc-4e28-11e8-90e2-be014acd0a66.png)

6. Click "API Keys" on the left navbar.

![screen shot 2018-05-02 at 4 24 30 pm](https://user-images.githubusercontent.com/17884966/39547400-7cdb854c-4e25-11e8-8442-7cfc1dc8bc1e.png)

7. Change your keys accordingly (name of Algolia key -> name of our application key): 
* `Application ID -> ALGOLIASEARCH_APPLICATION_ID`
* `Search-Only API Key -> ALGOLIASEARCH_SEARCH_ONLY_KEY`
* `Admin API KEY -> ALGOLIASEARCH_API_KEY`

![screen shot 2018-05-02 at 4 26 27 pm](https://user-images.githubusercontent.com/17884966/39547471-b24f2e36-4e25-11e8-9a0e-b988d6a8253f.png)

8. Done!

That's it! You should try logging in with development, it should work. If it doesn't, let us know via an issue or in the contributors channel!

### _The following are optional, but are probably things you'll run into. That said, if you're working on tests and other things, you shouldn't need these._

### For authentication, you can choose Twitter, GitHub, or both.

# Twitter App
1. [Click this link and sign in/sign up for a Twitter account.]((https://apps.twitter.com)) Note that your Twitter account will need a phone number linked to it in order to create an app.
2. Create a new app, and fill out the form, like the following example image: ![](https://user-images.githubusercontent.com/17884966/41612665-952d4cae-73c1-11e8-8047-cf0bd03bffb6.png)

The only important field is the "Callback URL" `http://localhost:3000/users/auth/twitter/callback`, which redirects you properly to `localhost:3000` when signing in.

3. Once done, go to your app's settings, and fill in the terms of service `http://dev.to/terms` and privacy policy URL `http://dev.to/privacy`:

![](https://user-images.githubusercontent.com/17884966/41617044-8155387a-73cd-11e8-9e1d-f14c4652bda2.png)

4. Once done, go to your app's permissions, and check the "Request email addresses from users" box.
![screen shot 2018-05-02 at 5 02 48 pm](https://user-images.githubusercontent.com/17884966/39549184-f2e19952-4e2a-11e8-81ad-10e06c4e8a61.png)

5. Change your keys accordingly: (name of Twitter key -> name of our application key):
- `Access Token -> TWITTER_KEY`
- `Access Token Secret -> TWITTER_SECRET`
6. Done! 

# GitHub
1. [Click this link and sign in/sign up for a GitHub account.](https://github.com/settings/applications/new)
2. Once signed in, create a new OAuth app. Here's an example; the URLs must match the example:
![screen shot 2018-04-26 at 4 08 01 pm](https://user-images.githubusercontent.com/17884966/39329488-77cbf554-496c-11e8-941e-dd257b5223ee.png)
3. Change your keys accordingly; (name of GitHub key -> name of our application key):
- `Client ID -> GITHUB_KEY`
- `Client Secret -> GITHUB_SECRET`
4. Done!

# Stream
1. [Sign up for an account with this link](https://getstream.io/accounts/signup/), using either your email or GitHub.

![stream step 1](https://user-images.githubusercontent.com/17884966/39548654-47db0f08-4e29-11e8-9cc3-c17d1b7228eb.png)

2. Click "View Dashboard" at the top right corner.

![stream step 2](https://user-images.githubusercontent.com/17884966/39548718-6f1928ca-4e29-11e8-9034-52ef1c1cc9d6.png)

3. **In the next page, click "Add New Feed Group".**

![stream step 3](https://user-images.githubusercontent.com/17884966/39548743-85bd4e44-4e29-11e8-9b6e-43567c4f7c22.png)

<hr>

4. Add a new feed group with the type "Notification" and name it `notifications` (case sensitive).

![stream step 4](https://user-images.githubusercontent.com/17884966/39548890-f0ad7742-4e29-11e8-84a3-ed823e720052.png)

5. Make sure you have a feed group with the type "Flat" and named `user` (case sensitive). You probably do, but if you don't, create one like you did with the notifications feed group.

6. Change your keys accordingly: (name of Stream key -> name of our application key):
  - `Key -> STREAM_RAILS_KEY`
  - `Secret -> STREAM_RAILS_SECRET`
  - `"https://us-east-api.stream-io-api.com/api/v1.0/" -> STREAM_URL`

7. Done!
