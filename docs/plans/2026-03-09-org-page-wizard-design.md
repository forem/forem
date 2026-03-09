# AI-Powered Org Page Wizard — Design Document

## Overview

A Gemini-powered wizard that generates beautiful organization pages using Forem's rich liquid tags. The wizard crawls provided URLs, mines DEV content, and produces a complete page that showcases the org with minimal user effort.

## User Journey

### Entry Points

- "Generate Page with AI" button on org settings page (for orgs with no page content)
- Post-org-creation redirect with prompt: "Set up your page with AI?"
- Both route to `/org-wizard/:slug`

### Step 1: "Tell us about your org"

- Header: "Setting up [Org Name]'s page" (org already exists)
- Primary URL input (required, 1 URL)
- Optional "Add another link" (up to 3 more — docs, blog, changelog, etc.)
- Submit triggers backend crawl
- Loading state with progress messages

### Step 2: "Here's what we found"

- Editable fields: tagline, description (pre-filled from crawl)
- Brand color swatch with "change" color picker
- Key links detected (informational)
- DEV posts section: checkboxes next to top posts (title, reactions, date), top 5 pre-checked
- Skips DEV posts sub-section if none found
- "Generate My Page" button triggers AI generation

### Step 3: "Your new page"

- Full live preview using actual org page renderer (real `processed_page_html`)
- Per-section overlay controls on hover: move up/down, remove, regenerate
- Free-text prompt bar pinned at bottom: "Tell AI what to change..." + "Apply"
- One iteration round supported
- "Looks good — Save Page" primary CTA
- "Start Over" secondary link

### Save

- Writes `page_markdown` to org
- Updates `bg_color_hex` if user accepted detected color
- Redirects to live org page with success toast

## Backend Architecture

### Routes

```ruby
scope "org-wizard/:slug" do
  get  "/",         to: "org_wizard#step1",    as: :org_wizard
  post "/crawl",    to: "org_wizard#crawl",    as: :org_wizard_crawl
  post "/generate", to: "org_wizard#generate", as: :org_wizard_generate
  post "/iterate",  to: "org_wizard#iterate",  as: :org_wizard_iterate
  post "/save",     to: "org_wizard#save",     as: :org_wizard_save
end
```

### Controller: OrgWizardController

- Inherits from `ApplicationController`
- `before_action`: authenticate user, load org by slug, verify user is org admin (Pundit)
- `step1` — renders wizard page (single Preact mount point)
- `crawl` — calls `Ai::OrgPageCrawler`, returns JSON (metadata, DEV posts, detected color)
- `generate` — calls `Ai::OrgPageGenerator` with confirmed data, returns JSON (markdown + rendered HTML)
- `iterate` — calls `Ai::OrgPageGenerator` with current markdown + feedback, returns JSON
- `save` — writes to org model, redirects

### Service: Ai::OrgPageCrawler

Handles Phase 1 (no AI call needed):

- Scrapes provided URLs via `metainspector` gem
- Extracts: title, description, OG image, key links
- Detects brand color (see Brand Color Detection below)
- Searches DEV: `Article.search_optimized(org_name)` for posts about/by the org, sorted by reactions
- Returns structured data object

### Service: Ai::OrgPageGenerator

Handles Phase 2 (Gemini call):

- Inherits from `Ai::Base`
- `generate(org_data:, dev_posts:, tag_reference:)` — initial page generation
- `iterate(current_markdown:, instruction:, context:)` — refinement from user feedback
- Validates output through `ContentRenderer.new(markdown, source: :organization).process`
- On validation failure: sends error back to Gemini, retries (max 2 retries)
- Falls back to best effort with broken sections stripped

## Frontend Architecture

### Single Preact Component: OrgWizard

Location: `app/javascript/orgWizard/`

State machine: `input → crawling → review → generating → preview → iterating → preview → saved`

**Step 1 (input):** URL inputs + submit button. Animated loading during crawl.

**Step 2 (review):** Editable metadata, color swatch, DEV post checkboxes. Submit triggers generation.

**Step 3 (preview):** Server-rendered HTML preview. Section overlay controls (hover). Free-text prompt bar. Save button.

**Iteration:** Free-text or section regenerate → POST `/iterate` → loading overlay → updated preview. Section remove is client-side (strips from markdown, re-renders).

## AI Prompt Strategy

### Liquid Tag Reference — Reuse Existing Pattern

The `Ai::EditorHelperService` already has a battle-tested approach for feeding liquid tag syntax to Gemini. It:
1. Reads three view partials: `_editor_guide_text.en.html.erb`, `_supported_url_embeds_list.en.html.erb`, `_supported_nonurl_embeds_list.en.html.erb`
2. Strips ERB/HTML to produce clean text with code examples
3. Caches the result for 12 hours (`Rails.cache.fetch("ai:editor_helper:guide")`)

**We reuse this exact approach.** Extract the guide-building logic into a shared module (e.g., `Ai::LiquidTagGuide`) that both `EditorHelperService` and `OrgPageGenerator` can call. This keeps the tag reference in sync — when new liquid tags are added to the editor guide, the wizard automatically picks them up.

Additionally, `OrgPageGenerator` appends an **org-specific supplement** covering the showcase tags most relevant to org pages:
- `features`/`feature` with icon and title options
- `quote` with author, role, rating
- `offer` with link and button text
- `org_posts` with slug, limit, sort options
- `org_team` with slug, limit, role options
- `org_lead_form` with form ID
- `slides`/`slide` with image/video/link options
- `row`/`col` with span options

This supplement includes 1-2 concrete examples per tag showing realistic org page usage.

### System Prompt Structure

```
You are a page designer for DEV.to organization pages.
Generate a beautiful, professional markdown page using liquid tags for {org_name}.

CONTEXT:
- Org description: {description}
- Tagline: {tagline}
- Key links: {links}
- Featured DEV posts: {post_titles_and_urls}

DEV EDITOR GUIDE & LIQUID TAG REFERENCE:
{shared_liquid_tag_guide}

ORG PAGE TAG SUPPLEMENT:
{org_specific_tag_examples}

RULES:
- Only use tags from the references above — no invented syntax
- Pick sections based on available content (skip what doesn't apply)
- Keep text concise and professional
- Use ## headings to separate sections
- Output raw markdown only, no explanations
```

### Iteration Prompt

```
Current page markdown:
{current_markdown}

User feedback: {instruction}

Update the page accordingly. Same rules apply.
```

### Section Selection Logic

AI decides which sections to include based on available content:
- Features/highlights: always (from crawled site data)
- Social proof (quotes): only if DEV comments found
- Popular on DEV: only if user selected posts in step 2
- Team: only if org has DEV members
- Lead form: only if org has a lead form configured
- Get started CTA: always (links to their site)
- Resources carousel: only if multiple resource links found

## Brand Color Detection

Detection chain (first success wins):

1. **Manifest file** — `<link rel="manifest">` → `theme_color`
2. **Meta theme-color** — `<meta name="theme-color">` (from metainspector)
3. **OG image dominant color** — Download, resize to 1x1 with MiniMagick, read color
4. **Favicon color** — Same 1x1 resize approach
5. **Fallback** — Empty, user picks manually

On save: writes to `org.bg_color_hex`. Auto-calculates `text_color_hex` for contrast via existing `Color::CompareHex`.

## Testing Strategy

### Backend (priority)

- **Service specs** for `Ai::OrgPageCrawler`: stub metainspector, verify metadata extraction, brand color detection, DEV search
- **Service specs** for `Ai::OrgPageGenerator`: stub Gemini responses, verify valid markdown, test retry logic, test iteration
- **Controller specs** for `OrgWizardController`: auth checks, JSON responses, save behavior
- **Request specs**: full flow crawl → generate → save, verify `page_markdown` populated

### Edge Cases

- URL returns 404 or times out → graceful error, user can retry or enter manually
- Zero DEV posts → skip that section
- Gemini returns malformed liquid tags → validation + retry (max 2)
- User is not org admin → 403
- Org already has a page → wizard works, save overwrites (with confirmation dialog)

### Frontend

Manual QA per AGENTS.md guidance. Clear descriptions of UI behavior for review.

## Technical Dependencies

All already in the project:
- `metainspector` gem — URL scraping
- `MiniMagick` — brand color extraction from images
- `fastimage` — image metadata
- `httparty` — HTTP requests (via `Ai::Base`)
- Gemini API (`gemini-2.5-pro`) — page generation
- `ContentRenderer` — markdown validation
- `Color::CompareHex` — color contrast calculation
