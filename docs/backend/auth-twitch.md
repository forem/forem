---
title: Twitch Authentication
---

# Twitch App and Authentication

Forem allows you to authenticate using Twitch. In order to use this
authentication method in local development, you will need to setup a Twitch App
and retrieve its keys. Then you'll need to provide these keys to the Rails
application.

## Sign up

1. [Sign in](https://www.twitch.tv) to your Twitch account.

2. In order to get the API keys, you will have to sign up for the
   [Twitch developers console](https://dev.twitch.tv/console).

## Get API keys

1. Once signed into the
   [Twitch developers console](https://dev.twitch.tv/console), choose "Register
   Your Application."

2. Give it a **Name**

3. Enter the redirect url with
   `https://<your domain>>/users/auth/twitch/callback`

4. Choose a category and click "Create"

5. Make note of **Client ID**

6. Click "New Secret" to generate a new **Client Secret**, and make note of it.

7. Go to your forem's **admin/config page**. Enable Twitch and paste the
   **Client ID** and the **Client Secret** into the respective fields.
