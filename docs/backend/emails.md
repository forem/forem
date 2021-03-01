---
title: Emails
---

# Previewing emails in development

You can view email previews at <http://localhost:3000/rails/mailers>.

Previews are setup in the directory `spec/mailers/previews`.

# Overriding mailer templates

To update the contents of emails that the app sends, edit the views under `app/views/mailers`. Note that this app uses the [`devise_invitable` gem](https://github.com/scambra/devise_invitable) for invitations. The views for this gem are stored under `app/views/devise/mailer`.
