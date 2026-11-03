# CAPTCHA providers

Provider selection is centralized in `Captcha::PROVIDERS`. Each provider supplies
its verification, widget partial, availability, and presentation through the same
interface. Shared `Captcha::CheckEnabled` and `Captcha::CheckRegistrationEnabled`
rules determine which submissions require verification; adding a provider does
not require adding provider branches to the protected controllers or forms.
The existing `ReCaptcha` eligibility constants remain aliases for compatibility.

Forem supports Google reCAPTCHA, Cloudflare Turnstile, and hCaptcha. Google reCAPTCHA is the
default, so existing installations keep using their configured reCAPTCHA keys
without changing settings.

## Configure a provider

1. In Admin's Authentication settings, edit the email address registration
   settings.
2. Check **Enable CAPTCHA for email password registration** to reveal the CAPTCHA
   settings.
3. Configure the new provider's site key and secret key before switching providers.
   Select Google reCAPTCHA, Cloudflare Turnstile, or hCaptcha, then save the settings.
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
compatible with the existing checkbox widget. For Turnstile, create a **Managed** widget and
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

## Turnstile behavior

Only the visible Managed widget is supported. Do not create an Invisible widget;
Forem does not offer an invisible mode or a widget-mode selector. The mode belongs
to the widget configuration in Cloudflare, not to the site key fields in Forem.
Managed mode can verify visitors automatically or show a checkbox when needed.

Signup widgets use the `signup` action and report-abuse widgets use `abuse_report`.
Server-side verification requires the selected form's exact action as well as a
successful result and matching hostname. A token issued for one form cannot be
used to authorize the other. Tokens expire after five minutes and are single-use;
failed submissions re-render or reload the form with a fresh widget, preserving
report text. Widgets are also refreshed after InstantClick navigation and history
restoration. Forms opened before deploying action validation must be refreshed.

## hCaptcha behavior

Use a standard visible hCaptcha widget. Enter its site key and secret key, then
select hCaptcha in Authentication settings. Invisible widgets and Enterprise
scoring are not supported. A selected hCaptcha provider with missing credentials
blocks protected submissions rather than disabling verification.

The server posts `h-captcha-response` to hCaptcha's Siteverify endpoint, including
the expected sitekey to prevent tokens issued for another sitekey from being
accepted. Verification requires `success: true`; expired, replayed, or invalid
tokens and service failures are rejected. Report text is retained on errors.
Widget setup and cleanup share the same InstantClick lifecycle as Turnstile.
The hCaptcha SDK's reCAPTCHA compatibility mode is disabled so it does not replace
Google's SDK when a visitor navigates between pages using different providers.

If your deployment sets a Content Security Policy, permit `https://hcaptcha.com`
and `https://*.hcaptcha.com` in `script-src`, `frame-src`, `style-src`, and
`connect-src`, as described in the [hCaptcha developer guide](https://docs.hcaptcha.com/).
Also permit outbound server requests to `https://api.hcaptcha.com/siteverify`.
Do not pin asset subdomains, which can change. Use separate non-production keys;
production must not use hCaptcha's public test credentials.
