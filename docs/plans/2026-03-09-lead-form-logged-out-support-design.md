# Lead Gen Form — Logged-Out Support

## Goal

Make the lead gen form work for both logged-in and logged-out users. Logged-in users keep the one-click submit (profile snapshot + DEV username). Logged-out users see an actual form with name, email, company, job title fields.

## Database Changes

- **Remove `location` column** from `lead_submissions`
- **Add `username` column** (string, nullable) — populated from `user.username` for logged-in submissions
- **Make `user_id` nullable** — anonymous submissions have no user reference
- **Replace unique index** on `[organization_lead_form_id, user_id]` with a partial unique index that only applies when `user_id IS NOT NULL` — logged-in users can't double-submit, anonymous duplicates are allowed

## Model Changes

- `LeadSubmission`: make `user` association optional, update `snapshot_from_user` to include `username` and drop `location`
- Remove location from validations/snapshot logic

## Controller Changes

- `LeadSubmissionsController#create`: remove `authenticate_user!` requirement for `create` (keep it for `check`). If `current_user` exists, snapshot from profile; otherwise, accept form params (name, email, company, job_title)
- Add strong params for anonymous submission fields

## View Changes

- `_org_lead_form.html.erb`: if logged in, show the current one-click button with data disclosure; if logged out, show a form with name/email/company/job_title fields and submit button. No disclosure notice for logged-out users.
- Update JS to POST form field data for anonymous submissions

## CSV Export

- Add `username` column
- Remove `location` column
- Anonymous submissions show blank username

## i18n

- Update all three locales (en, fr, pt): remove location references, add form field labels, update disclosure text for logged-in users
