---
title: Discord Authentication
---

# Discord App and Authentication

Forem allows you to authenticate using Discord. In order to use this
authentication method in local development, you will need to setup a Discord
App and retrieve its keys. Then you'll need to provide these keys to the Rails
application.

## Sign up

1. [Sign in](https://discord.com) to your Discord account.

2. In order to get the API keys, you will have to
   [convert your account to a developer account](https://discord.com/developers).

## Get API keys

1. Sign up or sign in to your [discord account](https://discord.com/developers)

2. From the **Applications** dashboard, click on **New Application**.

3. Give it a **Name**

4. Make note of **Client ID** and the **Client Secret**.

5. Go to **OAuth2** tab, and enter the redirect url with `https://<your domain>>/users/auth/discord/callback`

7. Paste the **Client ID** and the **Client Secret** to your `.env` file accordingly (name of Discord key -> name
   of our `SiteConfig` variable).

   ```text
   export DISCORD_CLIENT_ID="your client id"
   export DISCORD_CLIENT_SECRET="your client secret"
   ```
