# CAPTCHA providers

Forem supports Google reCAPTCHA and Cloudflare Turnstile. Google reCAPTCHA is the
default, so existing installations keep using their configured reCAPTCHA keys
without changing settings.

## Configure a provider

1. In Admin's Authentication settings, edit the email address registration
   settings.
2. Check **Enable CAPTCHA for email password registration** to reveal the CAPTCHA
   settings.
3. Configure the new provider's site key and secret key before switching providers.
   Select Google reCAPTCHA or Cloudflare Turnstile, then save the settings.
   The other provider's keys can remain configured; only the selected provider is
   used. Keep secret keys private. Public forms receive only the site key.

Selecting Turnstile without both valid keys blocks protected submissions rather
than disabling verification. Configure and verify the keys before switching a
live community to Turnstile.

The provider selection is shared by email/password signup and the report-abuse
form. The checkbox controls signup only: unchecking it does not disable CAPTCHA
on report-abuse forms. To configure report-abuse protection without requiring a
signup CAPTCHA, check the box to edit the provider and keys, then uncheck it before
saving. Existing report-abuse eligibility rules still apply.

## Keys and hostnames

Create the keys in the selected provider's dashboard. For reCAPTCHA, use keys
compatible with the existing checkbox widget. For Turnstile, create a widget and
copy its site key and secret key into the Turnstile fields. Configure the widget's
allowed hostnames for every hostname that serves your Forem, including staging or
development hosts when applicable. Keys from one provider do not work with the
other provider.

After saving, check signup and report-abuse forms on the configured hostname and
verify that both valid and invalid submissions behave as expected. Switching the
provider does not automatically change deployment configuration, DNS, or network
policies. This feature requires no database migration, new environment variables,
or new dependencies. If your deployment restricts browser resources or outbound
requests, allow the selected provider's widget and verification endpoints
separately.
