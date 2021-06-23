---
title: Emails
---

# Setting up email

If you would like to enable transactional email using services like SendGrid or
Mailgun, you can configure it by using the following environment variables:

```shell
SMTP_ADDRESS=         # ie. "smtp.sendgrid.net"
SMTP_PORT=            # ie. 587
SMTP_DOMAIN=
SMTP_USER_NAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=  # defaults to :plain
```

We follow the standard `ActionMailer` configuration. For more info, please check out
Rails'
[official documentation](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration).

# Previewing emails in development

You can view email previews at <http://localhost:3000/rails/mailers>.

Previews are setup in the directory `spec/mailers/previews`.

# Overriding mailer templates

To update the contents of emails that the app sends, edit the views under
`app/views/mailers`. Note that this app uses the
[`devise_invitable` gem](https://github.com/scambra/devise_invitable) for
invitations. The views for this gem are stored under `app/views/devise/mailer`.
