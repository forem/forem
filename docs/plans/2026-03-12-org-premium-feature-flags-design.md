# Org Premium Feature Flags — Design

## Problem

Two org features — readme pages and lead forms — need to be manually enabled by admins on a per-org basis as premium features. When a feature is not enabled for an org, the org admin should see an upgrade CTA pointing them to our partnerships/sales team. This system should be extensible for future premium features.

## Approach: Flipper Per-Org Flags + Settings::General CTA Config

Use the existing Flipper feature flag system (via `FeatureFlag` wrapper) with per-actor (per-org) enablement. A shared upgrade CTA is configured site-wide in `Settings::General`.

### Why Flipper

- Already in the codebase (`FeatureFlag` service wrapping Flipper gem)
- Natively supports per-actor flags: `FeatureFlag.enable(:org_readme, org)`
- No migrations on the organizations table for each new premium feature
- Can enable globally (`FeatureFlag.enable(:org_readme)`) or per-org
- Adding a future premium feature = just a new flag name

### Why not boolean columns

- Each new premium feature would require a migration
- Flipper already handles this use case cleanly

## Feature Gating

### Organization as Flipper Actor

Organization needs a `flipper_id` method to be used as a Flipper actor. The existing `FeatureFlag::Actor` wrapper can handle this, but for cleaner usage we add `flipper_id` directly to Organization:

```ruby
# app/models/organization.rb
def flipper_id
  "Organization;#{id}"
end
```

### Flag Names

- `:org_readme` — gates readme/page editing in org settings and readme display on profile
- `:org_lead_forms` — gates lead form management in org settings

### Checking Access

```ruby
FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[@organization])
FeatureFlag.enabled?(:org_lead_forms, FeatureFlag::Actor[@organization])
```

### Admin Toggles

The admin org show page (`/admin/content_manager/organizations/:id`) gets toggle buttons for each premium feature, following the existing pattern for `fully_trusted` and `verified`:

- Dedicated PATCH routes: `update_premium_feature`
- Creates a Note for audit trail
- Flash message confirmation

## Readme Behavior

- **Flag off (default):** Org settings hides page/readme editing, shows upgrade CTA. Org profile always shows classic feed + team view regardless of whether pages exist.
- **Flag on:** Org settings exposes readme/page editing. If the org has built a readme page (`main_page.present?`), the profile shows it. If not, profile shows classic feed + team view. This matches the existing `is_readme` logic in `stories_controller.rb`.

### Gating Points

1. **`stories_controller.rb`** — the `is_readme` check must also require the flag:
   ```ruby
   is_readme = main_page.present? && FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[@organization])
   ```

2. **Org settings page** — hide/show the page editing section based on the flag. Show upgrade CTA when flag is off.

## Lead Forms Behavior

- **Flag off (default):** The "Lead Forms" sidebar link in org settings is visible but the page shows an upgrade CTA card instead of lead form management.
- **Flag on:** Full lead forms functionality as-is.

### Gating Points

1. **`OrganizationLeadFormsController`** — add a before_action that checks the flag. If disabled, render the upgrade CTA view instead.

2. **Org settings sidebar** — the link remains visible (so org admins know the feature exists) but leads to the CTA page.

## Shared Upgrade CTA

A single set of `Settings::General` entries used for all premium feature CTAs:

```ruby
# app/models/settings/general.rb
setting :premium_features_cta_text, type: :string, default: "This is a premium feature. Contact our partnerships team to get started."
setting :premium_features_cta_url, type: :string
```

- `premium_features_cta_text` — the message shown to org admins
- `premium_features_cta_url` — link destination (mailto, Typeform, Calendly, etc.)

The CTA is rendered as a card in place of the gated feature UI. Reusable partial for consistency across all premium features.

## Admin UI

### Admin Org Show Page

New "Premium Features" card on the admin org show page with toggles for each feature:

- **Readme** — Enable/Disable button, description of what it unlocks
- **Lead Forms** — Enable/Disable button, description of what it unlocks

Each toggle calls a dedicated PATCH route and creates an audit Note.

### Admin General Settings

New fields in the general settings admin page for the CTA text and URL.

## i18n

All new strings must be added to `en.yml`, `fr.yml`, and `pt.yml` locale files:

- Admin org show page labels/descriptions for premium feature toggles
- Flash messages for enable/disable
- Upgrade CTA default text
- Controller flash messages

## Testing

- Request specs for admin toggle endpoints (enable/disable each flag, audit note creation)
- Request spec for org profile with flag on/off (readme display gating)
- Request spec for lead forms controller with flag on/off (CTA vs. full UI)
- Model spec for `Organization#flipper_id`
- Feature flag integration specs
