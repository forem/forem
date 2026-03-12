# Org Premium Feature Flags Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Gate readme and lead form features behind Flipper per-org flags, with a shared configurable upgrade CTA for orgs that don't have access.

**Architecture:** Use existing Flipper feature flag system (`FeatureFlag` wrapper) with per-actor (per-org) enablement. Two flags: `:org_readme` and `:org_lead_forms`. A shared upgrade CTA is configured in `Settings::General`. Admin org show page gets toggle buttons for each flag. Org settings and profile conditionally render based on flag status.

**Tech Stack:** Rails, Flipper, FeatureFlag service, RSpec, i18n (en/fr/pt)

---

### Task 1: Add flipper_id to Organization model

**Files:**
- Modify: `app/models/organization.rb:175-181` (before `private` on line 183)
- Test: `spec/models/organization_spec.rb`

**Step 1: Write the failing test**

Add to `spec/models/organization_spec.rb` after the `#readme_page?` describe block (after line 462):

```ruby
describe "#flipper_id" do
  it "returns a string with Organization prefix and id" do
    expect(organization.flipper_id).to eq("Organization;#{organization.id}")
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/models/organization_spec.rb -e "flipper_id" --format documentation`
Expected: FAIL with NoMethodError

**Step 3: Write minimal implementation**

In `app/models/organization.rb`, add after `header_cta_dropdown?` method (after line 181, before `private`):

```ruby
def flipper_id
  "Organization;#{id}"
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/models/organization_spec.rb -e "flipper_id" --format documentation`
Expected: PASS

**Step 5: Commit**

```bash
git add app/models/organization.rb spec/models/organization_spec.rb
git commit -m "Add flipper_id to Organization for per-org feature flags"
```

---

### Task 2: Add data update script to register Flipper flags

**Files:**
- Create: `lib/data_update_scripts/20260312000001_add_org_premium_feature_flags.rb`
- Test: Manual verification via `FeatureFlag.exist?`

**Step 1: Create the data update script**

Follow the existing pattern from `lib/data_update_scripts/20230725143428_add_billboard_location_targeting_feature_flag.rb`:

```ruby
module DataUpdateScripts
  class AddOrgPremiumFeatureFlags
    def run
      FeatureFlag.add(:org_readme)
      FeatureFlag.add(:org_lead_forms)
    end
  end
end
```

**Step 2: Commit**

```bash
git add lib/data_update_scripts/20260312000001_add_org_premium_feature_flags.rb
git commit -m "Add data update script to register org premium feature flags"
```

---

### Task 3: Add Settings::General entries for upgrade CTA

**Files:**
- Modify: `app/models/settings/general.rb:157` (after last setting, before class methods)
- Test: `spec/models/settings/general_spec.rb` (if it exists, otherwise manual)

**Step 1: Add the settings**

In `app/models/settings/general.rb`, add after line 157 (`display_algolia_branding` setting) and before the `def self.algolia_search_enabled?` method on line 159:

```ruby
# Premium features
setting :premium_features_cta_text, type: :string,
        default: "This is a premium feature. Contact our partnerships team to learn more."
setting :premium_features_cta_url, type: :string
```

**Step 2: Commit**

```bash
git add app/models/settings/general.rb
git commit -m "Add Settings::General entries for premium features upgrade CTA"
```

---

### Task 4: Add admin controller action for toggling premium features

**Files:**
- Modify: `app/controllers/admin/organizations_controller.rb:103` (before `destroy` action)
- Modify: `config/routes/admin.rb:108` (add new route)
- Test: `spec/requests/admin/organizations_premium_features_spec.rb`

**Step 1: Write the failing tests**

Create `spec/requests/admin/organizations_premium_features_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "/admin/content_manager/organizations premium features" do
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { create(:organization) }

  before do
    sign_in(admin)
    FeatureFlag.add(:org_readme)
    FeatureFlag.add(:org_lead_forms)
  end

  after do
    FeatureFlag.disable(:org_readme)
    FeatureFlag.disable(:org_lead_forms)
  end

  describe "PATCH /admin/organizations/:id/update_premium_feature" do
    it "enables org_readme for an organization" do
      patch update_premium_feature_admin_organization_path(organization),
            params: { feature: "org_readme", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])).to be(true)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("enabled")
    end

    it "disables org_readme for an organization" do
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])

      patch update_premium_feature_admin_organization_path(organization),
            params: { feature: "org_readme", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[organization])).to be(false)
      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:notice]).to include("disabled")
    end

    it "enables org_lead_forms for an organization" do
      patch update_premium_feature_admin_organization_path(organization),
            params: { feature: "org_lead_forms", enabled: "true" }

      expect(FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[organization])).to be(true)
    end

    it "disables org_lead_forms for an organization" do
      FeatureFlag.enable(:org_lead_forms, FeatureFlag::Actor[organization])

      patch update_premium_feature_admin_organization_path(organization),
            params: { feature: "org_lead_forms", enabled: "false" }

      expect(FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[organization])).to be(false)
    end

    it "creates a note when toggling a feature" do
      expect do
        patch update_premium_feature_admin_organization_path(organization),
              params: { feature: "org_readme", enabled: "true" }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.noteable).to eq(organization)
      expect(note.author).to eq(admin)
      expect(note.content).to include("org_readme")
    end

    it "rejects unknown feature names" do
      patch update_premium_feature_admin_organization_path(organization),
            params: { feature: "org_evil_feature", enabled: "true" }

      expect(response).to redirect_to(admin_organization_path(organization))
      expect(flash[:error]).to be_present
    end
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/admin/organizations_premium_features_spec.rb --format documentation`
Expected: FAIL (route not found)

**Step 3: Add the route**

In `config/routes/admin.rb`, add after line 108 (`patch "update_verified"`):

```ruby
patch "update_premium_feature"
```

**Step 4: Write the controller action**

In `app/controllers/admin/organizations_controller.rb`, add before the `destroy` method (before line 104):

```ruby
PREMIUM_FEATURES = %w[org_readme org_lead_forms].freeze

def update_premium_feature
  org = Organization.find(params[:id])
  feature = params[:feature]

  unless PREMIUM_FEATURES.include?(feature)
    flash[:error] = I18n.t("admin.organizations_controller.premium_feature_invalid")
    return redirect_to admin_organization_path(org)
  end

  actor = FeatureFlag::Actor[org]
  if params[:enabled] == "true"
    FeatureFlag.enable(feature.to_sym, actor)
  else
    FeatureFlag.disable(feature.to_sym, actor)
  end

  status = params[:enabled] == "true" ? "enabled" : "disabled"
  Note.create(
    author_id: current_user.id,
    noteable_id: org.id,
    noteable_type: "Organization",
    reason: "misc_note",
    content: "Premium feature '#{feature}' #{status}",
  )

  flash[:notice] = I18n.t("admin.organizations_controller.premium_feature_#{status}", feature: feature.humanize)
  redirect_to admin_organization_path(org)
end
```

**Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/admin/organizations_premium_features_spec.rb --format documentation`
Expected: PASS

**Step 6: Commit**

```bash
git add config/routes/admin.rb app/controllers/admin/organizations_controller.rb spec/requests/admin/organizations_premium_features_spec.rb
git commit -m "Add admin controller action for toggling org premium features"
```

---

### Task 5: Add i18n strings for premium features

**Files:**
- Modify: `config/locales/controllers/admin/en.yml:121`
- Modify: `config/locales/controllers/admin/fr.yml:121`
- Modify: `config/locales/controllers/admin/pt.yml:86`
- Modify: `config/locales/views/admin/en.yml:500` (after fully_trusted section)
- Modify: `config/locales/views/admin/fr.yml:487` (after fully_trusted section)
- Modify: `config/locales/views/admin/pt.yml:378` (after fully_trusted section)

**Step 1: Add controller i18n strings**

In `config/locales/controllers/admin/en.yml`, after `verified_disabled` (line 121):

```yaml
      premium_feature_enabled: "%{feature} has been enabled for this organization."
      premium_feature_disabled: "%{feature} has been disabled for this organization."
      premium_feature_invalid: "Invalid premium feature specified."
```

In `config/locales/controllers/admin/fr.yml`, after `verified_disabled` (line 121):

```yaml
      premium_feature_enabled: "%{feature} a été activé pour cette organisation."
      premium_feature_disabled: "%{feature} a été désactivé pour cette organisation."
      premium_feature_invalid: "Fonctionnalité premium spécifiée invalide."
```

In `config/locales/controllers/admin/pt.yml`, after `verified_disabled` (line 86):

```yaml
      premium_feature_enabled: "%{feature} foi habilitado para esta organização."
      premium_feature_disabled: "%{feature} foi desabilitado para esta organização."
      premium_feature_invalid: "Funcionalidade premium especificada inválida."
```

**Step 2: Add view i18n strings**

In `config/locales/views/admin/en.yml`, after the `fully_trusted` section (after `enabled_notice` line ~500):

```yaml
        premium_features:
          heading: Premium Features
          readme:
            label: Readme Page
            description: When enabled, this organization can build and display a custom readme page on their profile.
            enable: Enable Readme
            disable: Disable Readme
            enabled_notice: Readme page feature is enabled for this organization.
          lead_forms:
            label: Lead Forms
            description: When enabled, this organization can create and manage lead capture forms to embed in their articles.
            enable: Enable Lead Forms
            disable: Disable Lead Forms
            enabled_notice: Lead forms feature is enabled for this organization.
```

In `config/locales/views/admin/fr.yml`, after the `fully_trusted` section:

```yaml
        premium_features:
          heading: Fonctionnalités Premium
          readme:
            label: Page Readme
            description: Lorsqu'elle est activée, cette organisation peut créer et afficher une page readme personnalisée sur son profil.
            enable: Activer le Readme
            disable: Désactiver le Readme
            enabled_notice: La fonctionnalité de page readme est activée pour cette organisation.
          lead_forms:
            label: Formulaires de leads
            description: Lorsqu'elle est activée, cette organisation peut créer et gérer des formulaires de capture de leads à intégrer dans ses articles.
            enable: Activer les formulaires de leads
            disable: Désactiver les formulaires de leads
            enabled_notice: La fonctionnalité de formulaires de leads est activée pour cette organisation.
```

In `config/locales/views/admin/pt.yml`, after the `fully_trusted` section:

```yaml
        premium_features:
          heading: Funcionalidades Premium
          readme:
            label: Página Readme
            description: Quando habilitado, esta organização pode criar e exibir uma página readme personalizada em seu perfil.
            enable: Habilitar Readme
            disable: Desabilitar Readme
            enabled_notice: A funcionalidade de página readme está habilitada para esta organização.
          lead_forms:
            label: Formulários de Leads
            description: Quando habilitado, esta organização pode criar e gerenciar formulários de captura de leads para incorporar em seus artigos.
            enable: Habilitar Formulários de Leads
            disable: Desabilitar Formulários de Leads
            enabled_notice: A funcionalidade de formulários de leads está habilitada para esta organização.
```

**Step 3: Add upgrade CTA i18n strings**

In `config/locales/views/organizations/en.yml`, add a new `premium_upgrade` section:

```yaml
    premium_upgrade:
      heading: Premium Feature
      cta_fallback: "This is a premium feature. Contact our partnerships team to learn more."
```

In `config/locales/views/organizations/fr.yml`:

```yaml
    premium_upgrade:
      heading: Fonctionnalité Premium
      cta_fallback: "Ceci est une fonctionnalité premium. Contactez notre équipe partenariats pour en savoir plus."
```

In `config/locales/views/organizations/pt.yml`:

```yaml
    premium_upgrade:
      heading: Funcionalidade Premium
      cta_fallback: "Esta é uma funcionalidade premium. Entre em contato com nossa equipe de parcerias para saber mais."
```

**Step 4: Commit**

```bash
git add config/locales/
git commit -m "Add i18n strings for org premium feature flags (en/fr/pt)"
```

---

### Task 6: Add premium features card to admin org show page

**Files:**
- Modify: `app/views/admin/organizations/show.html.erb:96` (after fully_trusted card, before verified card)

**Step 1: Add the premium features card**

Insert after line 96 (closing `</div>` of fully trusted card) and before line 98 (verified card):

```erb
<div class="crayons-card p-6 mb-6">
  <h3 class="crayons-subtitle-2 mb-4"><%= t("views.admin.organizations.premium_features.heading") %></h3>

  <% org_actor = FeatureFlag::Actor[@organization] %>

  <div class="mb-6">
    <div class="flex items-center justify-between mb-2">
      <div>
        <h4 class="fw-bold mb-1"><%= t("views.admin.organizations.premium_features.readme.label") %></h4>
        <p class="fs-s color-base-60"><%= t("views.admin.organizations.premium_features.readme.description") %></p>
      </div>
      <% readme_enabled = FeatureFlag.enabled?(:org_readme, org_actor) %>
      <%= form_tag update_premium_feature_admin_organization_path(@organization), method: :patch, class: "flex items-center gap-2" do %>
        <%= hidden_field_tag :feature, "org_readme" %>
        <%= hidden_field_tag :enabled, !readme_enabled %>
        <%= submit_tag readme_enabled ? t("views.admin.organizations.premium_features.readme.disable") : t("views.admin.organizations.premium_features.readme.enable"),
                       class: "crayons-btn #{readme_enabled ? 'crayons-btn--danger' : 'crayons-btn--success'}" %>
      <% end %>
    </div>
    <% if readme_enabled %>
      <div class="crayons-notice crayons-notice--success">
        <%= t("views.admin.organizations.premium_features.readme.enabled_notice") %>
      </div>
    <% end %>
  </div>

  <div class="mb-6">
    <div class="flex items-center justify-between mb-2">
      <div>
        <h4 class="fw-bold mb-1"><%= t("views.admin.organizations.premium_features.lead_forms.label") %></h4>
        <p class="fs-s color-base-60"><%= t("views.admin.organizations.premium_features.lead_forms.description") %></p>
      </div>
      <% lead_forms_enabled = FeatureFlag.enabled?(:org_lead_forms, org_actor) %>
      <%= form_tag update_premium_feature_admin_organization_path(@organization), method: :patch, class: "flex items-center gap-2" do %>
        <%= hidden_field_tag :feature, "org_lead_forms" %>
        <%= hidden_field_tag :enabled, !lead_forms_enabled %>
        <%= submit_tag lead_forms_enabled ? t("views.admin.organizations.premium_features.lead_forms.disable") : t("views.admin.organizations.premium_features.lead_forms.enable"),
                       class: "crayons-btn #{lead_forms_enabled ? 'crayons-btn--danger' : 'crayons-btn--success'}" %>
      <% end %>
    </div>
    <% if lead_forms_enabled %>
      <div class="crayons-notice crayons-notice--success">
        <%= t("views.admin.organizations.premium_features.lead_forms.enabled_notice") %>
      </div>
    <% end %>
  </div>
</div>
```

**Step 2: Commit**

```bash
git add app/views/admin/organizations/show.html.erb
git commit -m "Add premium features toggle card to admin org show page"
```

---

### Task 7: Create shared upgrade CTA partial

**Files:**
- Create: `app/views/shared/_premium_upgrade_cta.html.erb`

**Step 1: Create the partial**

```erb
<div class="crayons-card p-6 text-center">
  <div class="mb-4">
    <%= crayons_icon_tag("lock", class: "color-base-50", width: 48, height: 48) %>
  </div>
  <h3 class="crayons-subtitle-2 mb-2"><%= t("views.organization_settings.premium_upgrade.heading") %></h3>
  <p class="color-base-70 mb-4">
    <%= Settings::General.premium_features_cta_text.presence || t("views.organization_settings.premium_upgrade.cta_fallback") %>
  </p>
  <% if Settings::General.premium_features_cta_url.present? %>
    <a href="<%= Settings::General.premium_features_cta_url %>" class="crayons-btn" target="_blank" rel="noopener">
      <%= t("views.organization_settings.premium_upgrade.cta_fallback").split(".").first.strip %>
    </a>
  <% end %>
</div>
```

Note: The button text reuse is not great. Revisit in Step 2.

**Step 2: Improve the partial with a proper button label**

Add to the i18n files a `button_text` key:

In `config/locales/views/organizations/en.yml` under `premium_upgrade`:
```yaml
      button_text: "Learn More"
```

In `config/locales/views/organizations/fr.yml` under `premium_upgrade`:
```yaml
      button_text: "En savoir plus"
```

In `config/locales/views/organizations/pt.yml` under `premium_upgrade`:
```yaml
      button_text: "Saiba Mais"
```

Update the partial button to:
```erb
<a href="<%= Settings::General.premium_features_cta_url %>" class="crayons-btn" target="_blank" rel="noopener">
  <%= t("views.organization_settings.premium_upgrade.button_text") %>
</a>
```

**Step 3: Commit**

```bash
git add app/views/shared/_premium_upgrade_cta.html.erb config/locales/views/organizations/
git commit -m "Add shared premium upgrade CTA partial"
```

---

### Task 8: Gate readme feature in org settings page

**Files:**
- Modify: `app/views/organization_settings/edit.html.erb:131` (sidebar link) and `:157` (section-page content)

**Step 1: Write the test**

Add to `spec/requests/organization_settings_spec.rb` (or create if needed) — check that the page editor section is hidden when the flag is off:

```ruby
# In the appropriate describe block for organization settings
context "when org_readme feature is disabled" do
  it "shows upgrade CTA instead of page editor" do
    get organization_settings_path(@organization.slug)
    expect(response.body).to include("premium")
    expect(response.body).not_to include("org-page-editor-root")
  end
end

context "when org_readme feature is enabled" do
  before do
    FeatureFlag.add(:org_readme)
    FeatureFlag.enable(:org_readme, FeatureFlag::Actor[@organization])
  end

  after { FeatureFlag.disable(:org_readme) }

  it "shows page editor" do
    get organization_settings_path(@organization.slug)
    expect(response.body).to include("org-page-editor-root")
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/organization_settings_spec.rb -e "org_readme" --format documentation`
Expected: FAIL (page editor always shown)

**Step 3: Gate the section-page content**

In `app/views/organization_settings/edit.html.erb`, wrap the `#section-page` content. Around line 157, replace the page section with a conditional:

```erb
<div id="section-page" class="crayons-card crayons-card--content-rows">
  <h2><%= t("views.organization_settings.page.heading") %></h2>
  <% if FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[@organization]) %>
    <%# ... existing cover image + page editor content ... %>
  <% else %>
    <%= render "shared/premium_upgrade_cta" %>
  <% end %>
</div>
```

Keep the `<h2>` heading visible so the sidebar anchor still works. Wrap only the form fields inside the conditional.

**Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/organization_settings_spec.rb -e "org_readme" --format documentation`
Expected: PASS

**Step 5: Commit**

```bash
git add app/views/organization_settings/edit.html.erb spec/requests/organization_settings_spec.rb
git commit -m "Gate readme page editor behind org_readme feature flag"
```

---

### Task 9: Gate readme display on org profile

**Files:**
- Modify: `app/controllers/stories_controller.rb:188`
- Test: `spec/requests/stories_index_spec.rb`

**Step 1: Write the failing test**

Add to `spec/requests/stories_index_spec.rb` in the organization context:

```ruby
context "when org has a readme page but org_readme flag is disabled" do
  let(:organization) { create(:organization) }

  before do
    create(:page, organization: organization, body_markdown: "# Hello",
           title: organization.name, description: "desc", slug: "#{organization.slug}-page")
    FeatureFlag.add(:org_readme)
  end

  it "shows classic feed view instead of readme" do
    get "/#{organization.slug}"
    expect(response.body).not_to include("org-readme-show")
  end
end

context "when org has a readme page and org_readme flag is enabled" do
  let(:organization) { create(:organization) }

  before do
    create(:page, organization: organization, body_markdown: "# Hello",
           title: organization.name, description: "desc", slug: "#{organization.slug}-page")
    FeatureFlag.add(:org_readme)
    FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
  end

  after { FeatureFlag.disable(:org_readme) }

  it "shows readme view" do
    get "/#{organization.slug}"
    expect(response.body).to include("Hello")
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/stories_index_spec.rb -e "org_readme" --format documentation`
Expected: FAIL (readme always shown when page exists)

**Step 3: Gate the is_readme check**

In `app/controllers/stories_controller.rb`, change line 188 from:

```ruby
is_readme = main_page.present?
```

to:

```ruby
is_readme = main_page.present? && FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[@organization])
```

**Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/stories_index_spec.rb -e "org_readme" --format documentation`
Expected: PASS

**Step 5: Commit**

```bash
git add app/controllers/stories_controller.rb spec/requests/stories_index_spec.rb
git commit -m "Gate readme display on org profile behind org_readme feature flag"
```

---

### Task 10: Gate lead forms behind feature flag

**Files:**
- Modify: `app/controllers/organization_lead_forms_controller.rb:2-3`
- Modify: `app/views/organization_lead_forms/index.html.erb`
- Test: `spec/requests/organization_lead_forms_spec.rb`

**Step 1: Write the failing test**

Add to `spec/requests/organization_lead_forms_spec.rb`:

```ruby
context "when org_lead_forms feature is disabled" do
  it "shows upgrade CTA instead of lead form management" do
    get organization_lead_forms_path(organization.slug)
    expect(response.body).to include("premium")
    expect(response.body).not_to include("org_lead_form[title]")
  end
end

context "when org_lead_forms feature is enabled" do
  before do
    FeatureFlag.add(:org_lead_forms)
    FeatureFlag.enable(:org_lead_forms, FeatureFlag::Actor[organization])
  end

  after { FeatureFlag.disable(:org_lead_forms) }

  it "shows lead form management UI" do
    get organization_lead_forms_path(organization.slug)
    expect(response.body).to include("org_lead_form[title]")
  end
end
```

**Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/organization_lead_forms_spec.rb -e "org_lead_forms feature" --format documentation`
Expected: FAIL (lead form UI always shown)

**Step 3: Add feature flag check to controller**

In `app/controllers/organization_lead_forms_controller.rb`, add a before_action after line 2:

```ruby
before_action :check_lead_forms_feature
```

Add to the private section:

```ruby
def check_lead_forms_feature
  return if FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[@organization])

  @premium_gated = true
end
```

**Step 4: Gate the view**

In `app/views/organization_lead_forms/index.html.erb`, wrap the main content in a conditional. After the header (back link, around line 9), add:

```erb
<% if @premium_gated %>
  <%= render "shared/premium_upgrade_cta" %>
<% else %>
  <%# ... existing lead form management content ... %>
<% end %>
```

**Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/organization_lead_forms_spec.rb -e "org_lead_forms feature" --format documentation`
Expected: PASS

**Step 6: Commit**

```bash
git add app/controllers/organization_lead_forms_controller.rb app/views/organization_lead_forms/index.html.erb spec/requests/organization_lead_forms_spec.rb
git commit -m "Gate lead forms management behind org_lead_forms feature flag"
```

---

### Task 11: Run full test suite and fix any issues

**Step 1: Run all related specs**

```bash
bundle exec rspec spec/models/organization_spec.rb \
  spec/requests/admin/organizations_premium_features_spec.rb \
  spec/requests/stories_index_spec.rb \
  spec/requests/organization_lead_forms_spec.rb \
  --format documentation
```

**Step 2: Run existing org specs to check for regressions**

```bash
bundle exec rspec spec/requests/admin/organizations_spec.rb \
  spec/requests/admin/organizations_fully_trusted_spec.rb \
  spec/requests/admin/organizations_verified_spec.rb \
  spec/requests/admin/organizations_baseline_score_spec.rb \
  --format documentation
```

**Step 3: Fix any failures and commit**

```bash
git add -A
git commit -m "Fix any test regressions from premium feature flag gating"
```
