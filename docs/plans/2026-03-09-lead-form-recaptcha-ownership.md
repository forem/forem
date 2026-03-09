# Lead Form reCAPTCHA + Ownership Validation — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add reCAPTCHA to anonymous lead form submissions and validate that orgs can only embed their own lead forms.

**Architecture:** reCAPTCHA v2 widget added to the anonymous form section, verified server-side in the controller. Liquid tag validates form ownership by checking the form's organization_id against the parse context source.

**Tech Stack:** Rails 7, `recaptcha` gem (already in Gemfile), ERB, vanilla JS, RSpec

---

### Task 1: Add ownership validation to the liquid tag

**Files:**
- Modify: `app/liquid_tags/org_lead_form_tag.rb`
- Modify: `spec/liquid_tags/org_lead_form_tag_spec.rb`
- Modify: `config/locales/liquid_tags/en.yml` (line 182, add after `name_email_required`)
- Modify: `config/locales/liquid_tags/fr.yml` (line 182, add after `name_email_required`)
- Modify: `config/locales/liquid_tags/pt.yml` (line 182, add after `name_email_required`)

**Step 1: Write the failing test**

Add to `spec/liquid_tags/org_lead_form_tag_spec.rb`, inside the top-level describe block, after the "when form is inactive" context:

```ruby
context "when form belongs to a different organization" do
  it "raises an error" do
    other_org = create(:organization)
    other_form = create(:organization_lead_form, organization: other_org)
    expect { parse_tag(other_form.id.to_s) }.to raise_error(StandardError, I18n.t("liquid_tags.org_lead_form_tag.wrong_organization"))
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/liquid_tags/org_lead_form_tag_spec.rb -f doc`
Expected: New test fails — no error raised when embedding another org's form.

**Step 3: Update the liquid tag**

Replace `app/liquid_tags/org_lead_form_tag.rb` with:

```ruby
class OrgLeadFormTag < LiquidTagBase
  PARTIAL = "liquids/org_lead_form".freeze
  VALID_CONTEXTS = %w[Organization].freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @form_id = parse_form_id(input)
    @form = OrganizationLeadForm.find_by(id: @form_id)
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.not_found") unless @form
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.inactive") unless @form.active?

    source = parse_context.partial_options[:source]
    unless @form.organization_id == source.id
      raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.wrong_organization")
    end
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: { form: @form },
    )
  end

  private

  def parse_form_id(input)
    id = Integer(input.strip, exception: false)
    raise StandardError, I18n.t("liquid_tags.org_lead_form_tag.invalid_id") unless id&.positive?

    id
  end
end

Liquid::Template.register_tag("org_lead_form", OrgLeadFormTag)
```

Key changes from previous version:
- Added `VALID_CONTEXTS = %w[Organization].freeze` (line 3) — restricts tag to org pages only
- Added ownership check (lines 12-15) — compares form's org to source org from parse context

**Step 4: Add i18n keys**

In `config/locales/liquid_tags/en.yml`, add after the `name_email_required` line (line 182):

```yaml
      wrong_organization: This lead form does not belong to this organization.
```

In `config/locales/liquid_tags/fr.yml`, add after the `name_email_required` line (line 182):

```yaml
      wrong_organization: Ce formulaire de leads n'appartient pas à cette organisation.
```

In `config/locales/liquid_tags/pt.yml`, add after the `name_email_required` line (line 182):

```yaml
      wrong_organization: Este formulário de leads não pertence a esta organização.
```

**Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/liquid_tags/org_lead_form_tag_spec.rb -f doc`
Expected: All tests pass (existing + new ownership test).

**Step 6: Commit**

```bash
git add app/liquid_tags/org_lead_form_tag.rb spec/liquid_tags/org_lead_form_tag_spec.rb config/locales/liquid_tags/en.yml config/locales/liquid_tags/fr.yml config/locales/liquid_tags/pt.yml
git commit -m "Validate lead form ownership in liquid tag"
```

---

### Task 2: Add reCAPTCHA to anonymous lead form submissions

**Files:**
- Modify: `app/views/liquids/_org_lead_form.html.erb` (lines 20-46 signed-out section + JS)
- Modify: `app/controllers/lead_submissions_controller.rb` (create action, lines 23-29)
- Modify: `spec/requests/lead_submissions_spec.rb`
- Modify: `config/locales/controllers/en.yml` (line 97, add after `name_and_email_required`)
- Modify: `config/locales/controllers/fr.yml` (line 97, add after `name_and_email_required`)
- Modify: `config/locales/controllers/pt.yml` (line 97, add after `name_and_email_required`)

**Step 1: Write the failing tests**

Add to `spec/requests/lead_submissions_spec.rb`, inside the `"when not signed in"` context, after the existing tests:

```ruby
it "rejects anonymous submission when recaptcha fails" do
  allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return("test-site-key")
  allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return("test-secret-key")

  post "/lead_submissions", params: {
    organization_lead_form_id: lead_form.id,
    name: "Bot User",
    email: "bot@example.com",
    company: "Bot Corp",
    job_title: "Bot"
  }, as: :json

  expect(response).to have_http_status(:unprocessable_entity)
  parsed = response.parsed_body
  expect(parsed["success"]).to be false
  expect(parsed["error"]).to eq(I18n.t("lead_submissions.recaptcha_failed"))
end

it "allows anonymous submission when recaptcha is not configured" do
  allow(Settings::Authentication).to receive(:recaptcha_site_key).and_return(nil)
  allow(Settings::Authentication).to receive(:recaptcha_secret_key).and_return(nil)

  post "/lead_submissions", params: {
    organization_lead_form_id: lead_form.id,
    name: "Real User",
    email: "real@example.com",
    company: "Real Corp",
    job_title: "Dev"
  }, as: :json

  expect(response).to have_http_status(:ok)
  parsed = response.parsed_body
  expect(parsed["success"]).to be true
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/lead_submissions_spec.rb -f doc`
Expected: "rejects anonymous submission when recaptcha fails" fails (currently succeeds without recaptcha check). "allows anonymous submission when recaptcha is not configured" should pass already.

**Step 3: Update the controller**

Replace `app/controllers/lead_submissions_controller.rb` with:

```ruby
class LeadSubmissionsController < ApplicationController
  before_action :authenticate_user!, only: [:check]

  def check
    form_ids = params[:form_ids].to_s.split(",").map(&:to_i).select(&:positive?)
    submissions = current_user.lead_submissions.where(organization_lead_form_id: form_ids)
                              .pluck(:organization_lead_form_id, :created_at)
    result = submissions.to_h { |form_id, created_at| [form_id.to_s, created_at.iso8601] }
    render json: result
  end

  def create
    form = OrganizationLeadForm.find(params[:organization_lead_form_id])

    unless form.active?
      render json: { success: false, error: I18n.t("lead_submissions.inactive_form") }, status: :unprocessable_entity
      return
    end

    if current_user
      snapshot = LeadSubmission.snapshot_from_user(current_user)
      submission = form.lead_submissions.build(snapshot.merge(user: current_user))
    else
      attrs = anonymous_submission_params
      if attrs[:name].blank? || attrs[:email].blank?
        render json: { success: false, error: I18n.t("lead_submissions.name_and_email_required") }, status: :unprocessable_entity
        return
      end
      unless recaptcha_passed?
        render json: { success: false, error: I18n.t("lead_submissions.recaptcha_failed") }, status: :unprocessable_entity
        return
      end
      submission = form.lead_submissions.build(attrs)
    end

    if submission.save
      render json: { success: true }
    else
      render json: { success: false, error: submission.errors.full_messages.first }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: I18n.t("lead_submissions.not_found") }, status: :not_found
  end

  private

  def anonymous_submission_params
    params.permit(:name, :email, :company, :job_title)
  end

  def recaptcha_passed?
    return true unless ReCaptcha::CheckEnabled.call(nil)

    recaptcha_params = { secret_key: Settings::Authentication.recaptcha_secret_key }
    params["g-recaptcha-response"].present? && verify_recaptcha(recaptcha_params)
  end
end
```

Key change: Added `recaptcha_passed?` private method (lines 50-54) following the same pattern as `FeedbackMessagesController#recaptcha_verified?`. Called after name/email validation in the anonymous branch (lines 31-34).

**Step 4: Add i18n keys**

In `config/locales/controllers/en.yml`, add after `name_and_email_required` (line 97):

```yaml
    recaptcha_failed: Please complete the CAPTCHA verification.
```

In `config/locales/controllers/fr.yml`, add after `name_and_email_required` (line 97):

```yaml
    recaptcha_failed: Veuillez compléter la vérification CAPTCHA.
```

In `config/locales/controllers/pt.yml`, add after `name_and_email_required` (line 97):

```yaml
    recaptcha_failed: Por favor, complete a verificação CAPTCHA.
```

**Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/lead_submissions_spec.rb -f doc`
Expected: All 9 tests pass.

**Step 6: Commit**

```bash
git add app/controllers/lead_submissions_controller.rb spec/requests/lead_submissions_spec.rb config/locales/controllers/en.yml config/locales/controllers/fr.yml config/locales/controllers/pt.yml
git commit -m "Add reCAPTCHA verification for anonymous lead form submissions"
```

---

### Task 3: Add reCAPTCHA widget to the anonymous form view

**Files:**
- Modify: `app/views/liquids/_org_lead_form.html.erb` (signed-out section + JS)

**Step 1: Update the view**

In `app/views/liquids/_org_lead_form.html.erb`, add the reCAPTCHA widget inside the `lead-form-signed-out` div, after the job_title field (after line 36) and before the `lead-form-actions` div (line 37):

Insert between the job_title field div and the lead-form-actions div:

```erb
    <div class="lead-form-recaptcha mb-3" id="lead_form_recaptcha_<%= form.id %>"></div>
```

Then update the `submitLeadFormAnonymous` JS function to include the reCAPTCHA response token. In the IIFE at the bottom, after the `isLoggedIn` swap logic, add reCAPTCHA rendering for signed-out forms.

Replace the entire `<script>` block (lines 49-172) with:

```erb
<script>
  function submitLeadForm(button) {
    var formId = button.getAttribute('data-form-id');
    button.disabled = true;
    button.textContent = '<%= I18n.t("liquid_tags.org_lead_form_tag.submitting") %>';

    fetch('/lead_submissions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ organization_lead_form_id: formId })
    }).then(function(response) {
      return response.json();
    }).then(function(data) {
      if (data.success) {
        markFormSubmitted(button, new Date().toISOString());
      } else {
        button.textContent = data.error || '<%= I18n.t("liquid_tags.org_lead_form_tag.error") %>';
        button.disabled = false;
      }
    }).catch(function() {
      button.textContent = '<%= I18n.t("liquid_tags.org_lead_form_tag.error") %>';
      button.disabled = false;
    });
  }

  function submitLeadFormAnonymous(button) {
    var formId = button.getAttribute('data-form-id');
    var container = button.closest('.lead-form-signed-out');
    var name = container.querySelector('input[name="name"]').value.trim();
    var email = container.querySelector('input[name="email"]').value.trim();
    var company = container.querySelector('input[name="company"]').value.trim();
    var jobTitle = container.querySelector('input[name="job_title"]').value.trim();

    if (!name || !email) {
      var statusEl = container.querySelector('.lead-form-status');
      statusEl.textContent = '<%= I18n.t("liquid_tags.org_lead_form_tag.name_email_required") %>';
      statusEl.style.display = '';
      return;
    }

    var recaptchaResponse = '';
    var recaptchaEl = container.querySelector('.lead-form-recaptcha .g-recaptcha');
    if (recaptchaEl && typeof grecaptcha !== 'undefined') {
      var widgetId = recaptchaEl.getAttribute('data-widget-id');
      recaptchaResponse = widgetId ? grecaptcha.getResponse(parseInt(widgetId)) : grecaptcha.getResponse();
    }

    button.disabled = true;
    button.textContent = '<%= I18n.t("liquid_tags.org_lead_form_tag.submitting") %>';

    fetch('/lead_submissions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({
        organization_lead_form_id: formId,
        name: name,
        email: email,
        company: company,
        job_title: jobTitle,
        'g-recaptcha-response': recaptchaResponse
      })
    }).then(function(response) {
      return response.json();
    }).then(function(data) {
      if (data.success) {
        markFormSubmitted(button, null);
        container.querySelectorAll('input').forEach(function(input) { input.disabled = true; });
      } else {
        button.textContent = data.error || '<%= I18n.t("liquid_tags.org_lead_form_tag.error") %>';
        button.disabled = false;
        if (typeof grecaptcha !== 'undefined' && recaptchaEl) {
          var wId = recaptchaEl.getAttribute('data-widget-id');
          if (wId) grecaptcha.reset(parseInt(wId));
        }
      }
    }).catch(function() {
      button.textContent = '<%= I18n.t("liquid_tags.org_lead_form_tag.error") %>';
      button.disabled = false;
    });
  }

  function markFormSubmitted(button, isoDate) {
    button.disabled = true;
    button.textContent = '<%= I18n.t("liquid_tags.org_lead_form_tag.submitted") %>';
    button.classList.remove('crayons-btn--primary');
    button.classList.add('crayons-btn--secondary');
    button.style.opacity = '0.6';

    var statusEl = button.parentElement.querySelector('.lead-form-status');
    if (statusEl && isoDate) {
      var date = new Date(isoDate);
      var formatted = date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
      statusEl.textContent = '<%= I18n.t("liquid_tags.org_lead_form_tag.already_submitted", date: "DATEPLACEHOLDER") %>'.replace('DATEPLACEHOLDER', formatted);
      statusEl.style.display = '';
    }
  }

  (function() {
    var forms = document.querySelectorAll('.ltag-org-lead-form');
    if (!forms.length) return;

    var isLoggedIn = document.body.getAttribute('data-user-status') === 'logged-in';

    forms.forEach(function(f) {
      var signedInView = f.querySelector('.lead-form-signed-in');
      var signedOutView = f.querySelector('.lead-form-signed-out');
      if (isLoggedIn) {
        signedInView.style.display = '';
        signedOutView.style.display = 'none';
      }
    });

    if (isLoggedIn) {
      var ids = [];
      forms.forEach(function(f) { ids.push(f.getAttribute('data-lead-form-id')); });

      fetch('/lead_submissions/check?form_ids=' + ids.join(','), {
        credentials: 'same-origin'
      }).then(function(r) { return r.json(); }).then(function(data) {
        forms.forEach(function(f) {
          var id = f.getAttribute('data-lead-form-id');
          if (data[id]) {
            var btn = f.querySelector('.lead-form-signed-in .lead-form-submit-btn');
            if (btn) markFormSubmitted(btn, data[id]);
          }
        });
      }).catch(function() {});
    } else {
      // Render reCAPTCHA widgets for signed-out forms if grecaptcha is available
      if (typeof grecaptcha !== 'undefined') {
        forms.forEach(function(f) {
          var recaptchaContainer = f.querySelector('.lead-form-recaptcha');
          if (recaptchaContainer && !recaptchaContainer.querySelector('.g-recaptcha')) {
            var div = document.createElement('div');
            div.className = 'g-recaptcha';
            div.setAttribute('data-sitekey', recaptchaContainer.getAttribute('data-sitekey') || '');
            recaptchaContainer.appendChild(div);
            var widgetId = grecaptcha.render(div);
            div.setAttribute('data-widget-id', widgetId);
          }
        });
      }
    }
  })();
</script>
```

Also update the recaptcha container div to pass the site key as a data attribute. Change the recaptcha div (inserted after job title field) to:

```erb
    <div class="lead-form-recaptcha mb-3" id="lead_form_recaptcha_<%= form.id %>" data-sitekey="<%= Settings::Authentication.recaptcha_site_key %>"></div>
```

**Step 2: Manually test in browser**

- Visit an org page with a lead form while logged out → should see reCAPTCHA widget below form fields (if reCAPTCHA keys are configured)
- Visit while logged in → should NOT see reCAPTCHA (one-click view shown)
- Submit without completing reCAPTCHA → should get error

**Step 3: Commit**

```bash
git add app/views/liquids/_org_lead_form.html.erb
git commit -m "Add reCAPTCHA widget to anonymous lead form view"
```

---

### Task 4: Run full test suite and verify

**Step 1: Run all related tests**

Run: `bundle exec rspec spec/liquid_tags/org_lead_form_tag_spec.rb spec/models/lead_submission_spec.rb spec/requests/lead_submissions_spec.rb spec/requests/organization_lead_forms_spec.rb -f doc`
Expected: All tests pass.

**Step 2: No commit needed — this is verification only**
