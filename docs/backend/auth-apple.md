---
title: Apple Authentication (beta)
---

# Sign in with Apple Authentication

Forem allows you to authenticate using
[Sign in with Apple](https://developer.apple.com/sign-in-with-apple/). In order
to use this authentication method you'll need to be enrolled to the
[Apple Developer Program](https://developer.apple.com/programs/) in order to
retrieve the necessary credentials and an HTTPS supported URL for the callback
configuration (HTTP won't work). Then you'll need to provide the keys to the
Rails application.

#### Beta support

This authentication provider is currently marked as beta. This means it will be
available but hidden from public access until more thoroughly tested.

If you want to make this feature publicly available (without the state
parameter) you can enable the `apple_auth` feature flag from the Flipper
dashboard or the Rails console with `Flipper.enable(:apple_auth)`.

# Apple Developer Portal Configuration

[Register/Sign in](https://developer.apple.com/account) to your Apple Developer
Account.

## Service ID Configuration

1. [Create a Service ID](https://developer.apple.com/account/resources/identifiers/list/serviceId)

![Create Service ID](https://user-images.githubusercontent.com/6045239/92610177-a5cc9e00-f274-11ea-9f63-20d8356d0bee.png)

2. Name the Service and finalize the registration

![Naming Service ID](https://user-images.githubusercontent.com/6045239/92610168-a36a4400-f274-11ea-8f79-7516c0c6c9c3.png)

3. Configure Domains and Subdomains & the callback URL. This example uses
   [ngrok](https://ngrok.io) for HTTPS support.

![Callback URLS](https://user-images.githubusercontent.com/6045239/92610184-a8c78e80-f274-11ea-9439-a98c6b627567.png)

## Key Configuration

1. [Register a new Key](https://developer.apple.com/account/resources/authkeys/add).
   Enable the "Sign in with Apple" option and configure it so it's associated
   with the corresponding App ID

![Register a new Key](https://user-images.githubusercontent.com/6045239/92611125-b3ceee80-f275-11ea-9c00-e1b5ca2f9af0.png)

2. Download the Key

![Download the Key](https://user-images.githubusercontent.com/6045239/92611466-0f00e100-f276-11ea-912d-f8a74b6dfb04.png)

# Configuring the Rails Application

Now with both the Service ID and Key you'll need to enable Apple Authentication
and pass in the credentials in the admin dashboard
`/admin/customization/config`.

![Admin Authentication Configuration Dashboard](https://user-images.githubusercontent.com/6045239/92613383-25a83780-f278-11ea-94a7-b710da544c9d.png)

Add the corresponding configuration data. Make sure the PEM key you downloaded
has explicit linebreaks (`\n`), don't forget the one at the very end of it.

![Apple config](https://user-images.githubusercontent.com/6045239/92614087-e0d0d080-f278-11ea-8d20-45148e1a6b59.png)

Save the changes and restart your server for these values to take effect.

## Email configuration

Apple uses what they call Private Email Relay Service to hide user's emails. For
this to work first
[create a new email source](https://developer.apple.com/account/resources/services/list).

![Email configuration](https://user-images.githubusercontent.com/6045239/92612469-22607c00-f277-11ea-918d-697cf4a18b15.png)

Emails sent need to be authenticated and the configuration depends on the
different providers available:

- [Mailchimp](https://mailchimp.com/help/set-up-custom-domain-authentication-dkim-and-spf/)
- [SendGrid](https://sendgrid.com/docs/ui/account-and-settings/how-to-set-up-domain-authentication/)
- [SES](https://docs.aws.amazon.com/es_es/ses/latest/DeveloperGuide/send-email-authentication-dkim.html)
