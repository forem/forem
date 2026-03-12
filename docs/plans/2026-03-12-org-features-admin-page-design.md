# Org Features Admin Page — Design

## Problem

Need a dedicated admin page to manage org feature flags globally (enable for all orgs) and see which orgs have individual access. Also renaming "premium_features" to "org_features" throughout the codebase.

## Approach

### Rename

Rename all references from `premium_features` / `premium_upgrade` to `org_features` / `org_features_upgrade`:

- `PREMIUM_FEATURES` constant → `ORG_FEATURES`
- `premium_features_cta_text` / `premium_features_cta_url` → `org_features_cta_text` / `org_features_cta_url`
- `_premium_upgrade_cta.html.erb` → `_org_features_upgrade_cta.html.erb`
- All i18n keys updated accordingly
- Admin org show page card heading updated

### New Admin Page

**Route:** `GET /admin/content_manager/org_features`
**Controller:** `Admin::OrgFeaturesController`

**Page layout:**

1. **Feature cards** — one per feature (`:org_readme`, `:org_lead_forms`):
   - Feature name + description
   - Global toggle: "Enabled for all organizations" — calls `FeatureFlag.enable(:flag)` (no actor) or `FeatureFlag.disable(:flag)`
   - Per-org list (shown when global is off): table of orgs with the flag individually enabled, each row links to that org's admin show page (`admin_organization_path`)

2. **Upgrade CTA config** — bottom section:
   - Text field for `org_features_cta_text`
   - URL field for `org_features_cta_url`
   - Save button

### Querying per-org enablements

Flipper stores per-actor enablements in `flipper_gates` table. To list orgs with a flag enabled:

```ruby
Flipper.feature(:org_readme).actors_value
# Returns set of flipper_ids like ["Organization;123", "Organization;456"]
```

Extract org IDs, load orgs.

### Defaults

All flags off globally by default. The data update script calls `FeatureFlag.add` only, not `FeatureFlag.enable`.

### No new models or migrations

Everything uses existing Flipper infrastructure + Settings::General.
