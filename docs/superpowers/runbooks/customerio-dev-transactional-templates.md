# DEV → Customer.io transactional templates

Build checklist for the 27 transactional messages that `DeliveryMethods::CustomerIo` sends.
Workspace: **Major League Hacking (v2)** (`152482`).

**Status:** 9 of 27 built and active — 48 `dev_reset_password_instructions`, 49 `dev_invitation_instructions`,
50 `dev_confirmation_instructions`, 51 `dev_unlock_instructions`, 52 `dev_account_ownership_verification`,
53 `dev_magic_link`, 54 `dev_unread_notifications_email`, 55 `dev_feedback_resolution`, 56 `dev_export_email`.

## Conventions (read once)

- **Create at** Transactional → *Create message*. Set **Trigger name** to the slug in each row —
  that is what `transactional_message_id` in the Rails mailer resolves to. The numeric Message ID
  also works but the code uses slugs, so the slug must match exactly.
- **Editor:** use the **code editor** (rich text also works). Layouts do *not* work with Design
  Studio or drag-and-drop.
- **Layout:** open the email envelope → Layout → **DEV (v1.0.0)** (`/journeys/layouts/6`).
  The layout supplies `<html>`, the white card, the DEV logo header, and the unsubscribe footer.
  **Author only the body fragment** — no `<html>`, `<head>`, or `<body>` tags in the message.
- **Liquid:** every `message_data` key is referenced as `{{trigger.<key>}}`. Nested values work as
  `{{trigger.billboards_html.first}}`; arrays as `{% for a in trigger.articles %}`.
- **Subject / from / reply_to / to are set by Rails on every send and override whatever you type in
  the template.** Put anything in the subject field; it is discarded. (Verified in
  `app/services/delivery_methods/customer_io.rb:33-38` — the API payload is merged over the template.)
- **Supplied automatically** on every ApplicationMailer-descended send by
  `Deliverable#layout_message_data`: `name`, `signed_up_with_html`, `notification_settings_url`.
  The layout renders the last two; `name` is free for greetings. DeviseMailer does not get them.
- **Nullable keys** are marked `?`. Wrap them in `{% if trigger.x %}`, or Liquid renders an empty string.
- **Missing template = no email.** If a slug does not exist in the workspace the API call raises and
  the Sidekiq job fails. There is no SMTP fallback. Create all 27 before enabling the flag globally.

### Bulletproof button (use for every CTA)

DEV's mailers use `<a style="background:…">`, which collapses to unstyled text in Outlook.
Use this instead — it renders everywhere:

```html
<table role="presentation" border="0" cellpadding="0" cellspacing="0" style="margin:24px 0;">
  <tr>
    <td align="center" bgcolor="#3b49df" style="border-radius:8px;mso-padding-alt:14px 28px;">
      <a href="{{trigger.SOME_URL}}" target="_blank"
         style="display:inline-block;padding:14px 28px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;font-size:16px;font-weight:700;line-height:20px;color:#ffffff;text-decoration:none;border-radius:8px;">
        Button label
      </a>
    </td>
  </tr>
</table>
```

Brand colour is `#3b49df` (dev.to default, from `settings_user_experiences`).

---

## NotifyMailer — 17 messages

### 1. `dev_new_reply_email`
- [ ] Someone replies to your comment or post.
- Tags: `commenter_name`, `parent_type`, `comment_html` (pre-sanitised HTML, print raw),
  `comment_url`, `article_or_parent_title`, `unsubscribe_url`
- Body: H1 "{{trigger.commenter_name}} replied to you on DEV" → grey `#f8f8f8` quote box containing
  `re: <em>{{trigger.article_or_parent_title}}</em>` and `{{trigger.comment_html}}` → button "View reply".

### 2. `dev_new_follower_email`
- [ ] Someone follows you.
- Tags: `follower_name`, `follower_profile_url`, `unsubscribe_url`
- Body: H1 "{{trigger.follower_name}} just followed you on DEV" → button "View their profile" →
  grey note explaining follows prioritise your posts in their feed.
- ⚠️ Current email also shows the follower's avatar and total follower count. Neither is in
  `message_data` — drop them, or add keys (see Gaps).

### 3. `dev_new_mention_email`
- [ ] You are @mentioned in a post or comment.
- Tags: `mentioner_name`, `mentionable_type`, `mention_url`, `unsubscribe_url`
- Body: H2 "{{trigger.mentioner_name}} just mentioned you in their {{trigger.mentionable_type}}" →
  button "View on DEV".
- ⚠️ Current email inlines the comment body for comment mentions. Not in `message_data`.

### 4. `dev_unread_notifications_email`
- [x] Digest of unread notifications.
- Tags: `unread_count`, `notifications_url`, `community_name`, `unsubscribe_url`
- Body: H3 "You're popular!" → button "Read my notifications". `unread_count` is available if you
  want "You have {{trigger.unread_count}} unread notifications".

### 5. `dev_video_upload_complete`
- [ ] A video finishes processing.
- Tags: `article_title`, `article_url` (already points at `/edit`)
- Body: "your video is finished processing" → H2 with 🎥 link "Finalize and publish your video".

### 6. `dev_new_badge_email`
- [ ] A badge is awarded.
- Tags: `badge_name`, `badge_description?`, `badge_image_url`, `unsubscribe_url`
- Body: centred. "Congratulations! You received the **{{trigger.badge_name}}** badge!" →
  `<img src="{{trigger.badge_image_url}}" style="height:200px">` → `{% if trigger.badge_description %}`
  → button "Check out your profile".
- ⚠️ `rewarding_context_message` (the italic custom line) is not in `message_data`.

### 7. `dev_feedback_response`
- [ ] Acknowledges an abuse/CoC report.
- Tags: `community_name`
- Body: "Hi there," → thanks for flagging content that may violate the CoC / Terms, we're looking
  into it → "Thanks, The {{trigger.community_name}} Team".

### 8. `dev_feedback_resolution`
- [x] Admin resolves a feedback message.
- Tags: `email_body` (admin-authored, already HTML via `simple_format`)
- Body: just `{{trigger.email_body}}`.

### 9. `dev_user_contact`
- [ ] Admin contacts a user directly.
- Tags: `email_body` (admin-authored HTML)
- Body: just `{{trigger.email_body}}`.

### 10. `dev_account_deleted`
- [ ] Account deletion completed.
- Tags: `name`, `community_name`
- Body: "Hi {{trigger.name}}," → account successfully deleted → contact link → sign-off.

### 11. `dev_organization_deleted`
- [ ] Organization deletion completed.
- Tags: `name`, `org_name`, `community_name`
- Body: as above, "Your organization {{trigger.org_name}} … has been successfully deleted."

### 12. `dev_account_deletion_requested`
- [ ] User requests deletion; confirmation link.
- Tags: `name`, `confirmation_url`, `community_name`
- Body: "Your account deletion was requested." → button "Confirm account deletion" →
  **"The link will expire in 12 hours."**

### 13. `dev_export_email`
- [x] Data export ready. **Has a ZIP attachment** (added by the API call, not the template).
- Tags: `community_name`
- Body: H3 "Your content has been exported." → "Please check the attached file."

### 14. `dev_tag_mod_confirmation`
- [ ] User is made a tag moderator.
- Tags: `tag_name`, `tag_url`, `community_moderation_url`, `community_name`
- Body: long. "Hey!" → you're now a moderator for `#{{trigger.tag_name}}` → `<ul>` of 6 abilities
  (remove/add the tag, edit the tag landing page, 🧐 flag, set experience level, 👍/👎) →
  link to Community Moderation → "hit reply with questions" → DEV Mod Discord invite
  (`https://discord.gg/f5ARW5gxES`) → "Happy Modding!"
- Note: the Discord paragraph is `dev_to?`-only in Rails; hardcode it, this workspace is DEV-only.
- `name` comes from `layout_message_data`, so "Hey {{trigger.name}}!" works.

### 15. `dev_subforem_mod_confirmation`
- [ ] User is made a subforem moderator.
- Tags: `subforem_domain`, `subforem_url`, `community_moderation_url`, `community_name`
- Body: same shape as #14 with a 5-item `<ul>` (discoverability, community settings, content
  quality, moderation tools, inclusive environment).
- `name` comes from `layout_message_data`, so the greeting works as-is.

### 16. `dev_trusted_role`
- [ ] User granted Trusted Member.
- Tags: `community_name`, `trusted_member_guide_url?`
- Body: "Good news! You've been granted Trusted Member permissions" → bold note about the shield
  icon → `<ul>`: rank content 👎👍, rate experience level, flag with 🧐 →
  `{% if trusted_member_guide_url %}` Trusted Member Guide link `{% endif %}`.
- `name` comes from `layout_message_data`, so the greeting works as-is.

### 17. `dev_base_subscriber_role`
- [ ] DEV++ subscription starts.
- Tags: `community_name`
- Body: "thanks for subscribing to DEV++!" → bold link to the DEV++ Hub (`https://dev.to/++`) →
  early-bird caveat that some deals aren't live yet → "Happy coding ❤️".
- `name` comes from `layout_message_data`, so the greeting works as-is.

---

## DeviseMailer — 4 messages (all sent with `tracked: false`)

Rails forces link tracking off on these; do not add tracked links.

### 18. `dev_invitation_instructions`
- [x] Admin invites a user.
- Tags: `invite_url`, `custom_message?` (markdown→HTML), `custom_footnote?`, `community_name`
- Body: `{% if trigger.custom_message %}` render it `{% else %}` "Hello!" / "Someone invited you to
  {{trigger.community_name}}" / "Accept the invitation:" `{% endif %}` → button "Accept invitation"
  → `{% if trigger.custom_footnote %}` → "ignore this email if you weren't expecting it".
- ⚠️ `invitation_due_at` ("accept until …") is not in `message_data`.

### 19. `dev_confirmation_instructions`
- [x] Email confirmation at signup.
- Tags: `confirmation_url`, `name`, `community_name`
- Body: "Welcome {{trigger.name}}!" → "You can confirm your account email through the link below:"
  → button "Confirm my account".
- ⚠️ Forem *creator* signups get a completely different MJML template in Rails. `message_data` has
  no flag to distinguish, so creators would receive this one. Not a dev.to concern.

### 20. `dev_reset_password_instructions`
- [x] Password reset.
- Tags: `reset_url`, `name`, `community_name`
- Body: "Hello {{trigger.name}}!" → "Someone has requested a link to change your password." →
  button "Change my password" → small grey: "If you didn't request this, please ignore this email."
  and "Your password won't change until you access the link above and create a new one."
- Note: current email greets with the *email address*; `message_data` sends `name`. Slight copy change.

### 21. `dev_unlock_instructions`
- [x] Account locked after failed sign-ins.
- Tags: `unlock_url`, `name`, `community_name`
- Body: "Hello {{trigger.name}}!" → "Your account has been locked due to an excessive number of
  unsuccessful sign in attempts." → button "Unlock my account".

---

## VerificationMailer — 2 messages (also `tracked: false`)

### 22. `dev_account_ownership_verification`
- [x] Verify you still control this address.
- Tags: `verification_url`, `username`, `community_name`
- Body: "Hey {{trigger.username}}!" → "We're sending this email to verify that you've got access to
  this email address." → "If you have no idea why you're getting this email, please ignore it!" →
  button "Verify this email address".

### 23. `dev_magic_link`
- [x] Passwordless sign-in.
- Tags: `sign_in_token`, `magic_link_url`, `name`, `community_name`
- Body: H1 "Log in to {{trigger.community_name}}" → "Hey {{trigger.name}}!" → the code in a
  monospace block (2.5em, bold, letter-spacing 2px, `#f0f0f0` bg, 2px dashed `#ccc` border) →
  "Enter this code…" → `<hr>` → "**Alternatively** … click this direct link" →
  link "log in via magic link" → **"This code and the link will expire in 20 minutes."** →
  "If you didn't request this login, you can safely ignore this email."
- ⚠️ Highest-risk template: the code must be legible and the link must not be rewritten. Keep
  tracking off.

---

## Everything else — 4 messages

### 24. `dev_digest_email` (the hard one)
- [ ] Periodic content digest.
- Tags: `subject`, `articles[]`, `smart_summary?` (HTML), `billboards_html.first?`,
  `billboards_html.second?`, `email_end_phrase`, `unsubscribe_url`, `user_follows_any_subforems`
- Each `articles[]` entry: `title`, `summary`, and six identical URL aliases
  (`url`, `path`, `link`, `article_url`, `canonical_url`) — use `{{a.url}}`.
- Body:
  ```liquid
  <h1>{% if trigger.user_follows_any_subforems %}Forem Digest{% else %}DEV Digest{% endif %}</h1>
  <!-- greeting bar (#fafafa, 1px #eaeaea, radius 8) -->
  {% if trigger.smart_summary %}<!-- "✨ Digest Overview" card -->{{trigger.smart_summary}}{% endif %}
  {% if trigger.billboards_html.first %}<hr>{{trigger.billboards_html.first}}<hr>{% endif %}
  {% for a in trigger.articles %}
    <a href="{{a.url}}" style="font-weight:600;color:#111;font-size:18px;">{{a.title}}</a>
    <p style="color:#555;font-size:15px;">{{a.summary}}</p>
    {% unless forloop.last %}<hr style="border-top:1px solid #f5f5f5;">{% endunless %}
  {% endfor %}
  <p style="text-align:center;font-weight:600;">Happy coding ❤️</p>
  {% if trigger.billboards_html.second %}<hr>{{trigger.billboards_html.second}}<hr>{% endif %}
  <!-- "How to make your Digest better" + link to the tags page -->
  ```
- ⚠️ The greeting is "👋 Hey {first name}" in Rails; no name key is sent. Use a generic greeting.
- ⚠️ The "update your experience level" footer line is conditional on the user's setting in Rails;
  not in `message_data`. Either always show it or drop it.

### 25. `dev_pulse_survey`
- [ ] Survey invitation.
- Tags: `survey_type` (`industry` | `fun` | `pulse`), `survey_url`, `community_name`, `subject`
- Body: "Hi," → branch on `survey_type` for the intro line and the CTA label
  ("Take the DEV Industry Survey" / "Take this quick DEV Survey" / "Take the DEV Pulse Survey") →
  button → "Your responses are completely anonymous and your info will never be shared." →
  "Best, The {{trigger.community_name}} Team".
- ⚠️ `extra_email_context_paragraph` is not in `message_data`. `name` now comes from `layout_message_data`.

### 26. `dev_org_invitation`
- [ ] Invited to join an organization.
- Tags: `org_name`, `inviter_name?`, `confirmation_url`, `community_name`
- Body: H2 greeting → `{% if trigger.inviter_name %}`"{{trigger.inviter_name}} invited you to join
  {{trigger.org_name}}"`{% else %}`"You've been invited to join {{trigger.org_name}}"`{% endif %}` →
  what an organization is → button "Confirm invitation" → small grey fallback showing the raw
  `{{trigger.confirmation_url}}` (`word-break:break-all`).
- ⚠️ No `name` key for the greeting.

### 27. `dev_org_member_added`
- [ ] Added to an organization.
- Tags: `org_name`, `inviter_name?`, `org_url`, `community_name`
- Body: same shape as #26, "added you to" instead of "invited you to", button "View organization",
  raw `{{trigger.org_url}}` fallback.
- `name` comes from `layout_message_data`, so the greeting works as-is.

---

## Fidelity gaps — decide before launch

These are places where the current Rails email renders something the CIO template *cannot*, because
the value is not in `message_data`. Each is a one-line addition to the mailer's
`customerio_delivery_options` if you want parity:

| Template | Missing | Impact |
|---|---|---|
| `dev_new_follower_email` | follower avatar URL, total follower count | loses the avatar + "you now have N followers" |
| `dev_new_mention_email` | comment HTML | mention emails lose the quoted comment |
| `dev_new_badge_email` | `rewarding_context_message` | loses the custom italic line |
| `dev_digest_email` | recipient first name, `experience_level` set? | generic greeting; footer line always/never shown |
| `dev_pulse_survey` | `extra_email_context_paragraph`, name | loses per-survey context paragraph |
| `dev_invitation_instructions` | `invitation_due_at` | loses "accept until <date>" |
| `dev_org_invitation`, `dev_org_member_added`, `dev_tag_mod_confirmation`, `dev_subforem_mod_confirmation`, `dev_trusted_role`, `dev_base_subscriber_role` | recipient `name` | greeting becomes generic |

Also decided deliberately:

- **The production `custom_email_footer` is not ported.** It is a "Delivered via SendGrid — DEV's
  Official Email Service Provider" block, which is false once mail moves to Customer.io. It also
  contains Gmail-proxied (`ci3.googleusercontent.com`) image URLs and ahoy click-tracking links with
  tokens baked in from one specific past send.
- **`signed_up_with(@user)`** ("You signed up with GitHub…") is dropped — it needs the user's auth
  providers, which are not in `message_data`.
- **The magic-link CTA block** in `layouts/mailer.html.erb` is dropped — it is gated on
  `@user.page_views.last`, which is neither in `message_data` nor cheap to query.
- **Subforem branding**: the layout hardcodes the dev.to logo and `#3b49df`. Rails resolves logo,
  brand colour, and community name *per subforem*, and only `community_name` is passed through. Mail
  for the ~20 non-default subforems will carry DEV branding until `logo_url`/`brand_color` are added
  to the payload.
