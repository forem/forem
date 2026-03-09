# Lead Form — reCAPTCHA + Ownership Validation

## Goal

Add reCAPTCHA to anonymous lead form submissions to prevent bot spam. Add ownership validation to the liquid tag so orgs can only embed their own lead forms.

## reCAPTCHA for Anonymous Submissions

- Add reCAPTCHA widget to the signed-out form section (matching existing pattern from feedback_messages)
- JS sends `g-recaptcha-response` token with anonymous POST
- Controller verifies token via `verify_recaptcha` before creating anonymous submission
- Only shown/enforced when reCAPTCHA keys are configured (`ReCaptcha::CheckEnabled.call(nil)`)
- Logged-in users skip reCAPTCHA entirely

## Ownership Validation on Liquid Tag

- Add `VALID_CONTEXTS = %w[Organization].freeze` to `OrgLeadFormTag`
- After finding the form, check `@form.organization_id == source.id` where `source = parse_context.partial_options[:source]`
- Raise error if form doesn't belong to the current org

## i18n

- Add `recaptcha_failed` and `wrong_organization` error messages in en/fr/pt
