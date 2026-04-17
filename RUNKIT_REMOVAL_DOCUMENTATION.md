# RunKit Removal - Complete Documentation

**Date:** April 17, 2026  
**Scope:** Complete removal of RunKit integration from Forem platform  
**Status:** ✅ COMPLETE - All RunKit branding and execution removed

---

## Executive Summary

RunKit, a third-party JavaScript execution environment, has been completely removed from the Forem codebase. The platform no longer executes or renders interactive RunKit widgets. Legacy content containing RunKit tags now displays a generic code fallback, preserving content readability while eliminating external dependencies.

---

## Files Deleted

### Core Implementation Files
1. **`app/liquid_tags/runkit_tag.rb`**
   - Original RunKit Liquid tag handler
   - **Replaced by:** `app/liquid_tags/legacy_code_tag.rb`

2. **`app/views/liquids/_runkit.html.erb`**
   - Legacy RunKit view partial
   - **Status:** Deleted entirely (no longer needed)

### Test & Spec Files
3. **`spec/liquid_tags/runkit_tag_spec.rb`**
   - Unit tests for RunkitTag
   - **Replaced by:** `spec/liquid_tags/legacy_code_tag_spec.rb`

4. **`spec/support/runkit_tag_context.rb`**
   - Test helper context for RunKit tests
   - **Replaced by:** `spec/support/legacy_code_tag_context.rb`

5. **`spec/fixtures/files/article_with_runkit_tag.txt`**
   - Test fixture with RunKit markup
   - **Replaced by:** `spec/fixtures/files/article_with_legacy_code_tag.txt`

6. **`spec/fixtures/files/article_with_runkit_tag_with_preamble.txt`**
   - Test fixture with RunKit + preamble
   - **Replaced by:** `spec/fixtures/files/article_with_legacy_code_tag_with_preamble.txt`

---

## Files Renamed / Refactored

### Liquid Tag Handler
**`app/liquid_tags/legacy_code_tag.rb`** (formerly `runkit_tag.rb`)
- **Class Name:** `LegacyCodeTag` (was `RunkitTag`)
- **Purpose:** Handle legacy `{% runkit %}` tags by rendering static fallback
- **Key Changes:**
  - Fallback message: `"This code block is no longer available. The original code is shown below."`
  - CSS classes: `ltag-legacy-code-fallback` (was `ltag-runkit-fallback`)
  - Locale key: `liquid_tags.legacy_code_tag.invalid_tag` (was `liquid_tags.runkit_tag.runkit_tag_is_invalid`)
  - Still registered as `"runkit"` for backward compatibility: `Liquid::Template.register_tag("runkit", LegacyCodeTag)`

### Model Updates
**`app/models/article.rb`**
- **Method Renamed:** `replace_legacy_runkit_html` → `replace_legacy_code_html`
- **Purpose:** Transform legacy baked RunKit HTML to static fallback
- **Selector:** Still uses `.runkit-element` (for legacy baked HTML compatibility)
- **Fallback Call:** Now uses `LegacyCodeTag.fallback_html()`

**`app/models/comment.rb`**
- **Method Renamed:** `replace_legacy_runkit_html` → `replace_legacy_code_html`
- **Purpose:** Same as Article model
- **Selector:** Still uses `.runkit-element` (for legacy baked HTML compatibility)
- **Fallback Call:** Now uses `LegacyCodeTag.fallback_html()`

### Test Files
**`spec/liquid_tags/legacy_code_tag_spec.rb`** (formerly `runkit_tag_spec.rb`)
- **Spec Class:** `RSpec.describe LegacyCodeTag`
- **Test Name Updated:** `"generates a fallback block with the original source"`
- **Assertion Updated:** Verifies `"This code block is no longer available"`

**`spec/support/legacy_code_tag_context.rb`** (formerly `runkit_tag_context.rb`)
- **Shared Context:** `"with legacy code tag"` (was `"with runkit_tag"`)
- **Helper Methods Renamed:**
  - `compose_legacy_code_comment` (was `compose_runkit_comment`)
  - `expect_legacy_code_tag_to_be_visible` (was `expect_runkit_tag_to_be_visible`)
  - `expect_no_legacy_code_tag_to_be_visible` (was `expect_no_runkit_tag_to_be_visible`)

**`spec/system/comments/user_fills_out_comment_spec.rb`**
- Context: `"with legacy code tags"` (was `"with Runkit tags"`)
- Test descriptions updated to reference "legacy code tag"
- Helper variables renamed: `legacy_code_comment`, `legacy_code_comment2`

**`spec/system/articles/user_creates_an_article_spec.rb`**
- Context: `"with legacy code tag"` (was `"with Runkit tag"`)
- Fixture variables: `template_with_legacy_code_tag`, `template_with_legacy_code_tag_with_preamble`
- Test descriptions updated to reference "legacy code tag"

### Locale Files Updated
**`config/locales/liquid_tags/en.yml`**
- **Removed:** `runkit_tag.runkit_tag_is_invalid`
- **Added:** `legacy_code_tag.invalid_tag: "Invalid legacy code tag"`

**`config/locales/liquid_tags/fr.yml`**
- **Removed:** `runkit_tag.runkit_tag_is_invalid: "Le tag Runkit n'est pas valide"`
- **Added:** `legacy_code_tag.invalid_tag: "Balise de code hérité invalide"`

**`config/locales/liquid_tags/pt.yml`**
- **Removed:** `runkit_tag.runkit_tag_is_invalid: "Tag do Runkit é inválida"`
- **Added:** `legacy_code_tag.invalid_tag: "Tag de código legado inválida"`

---

## Code Removed / Eliminated

### JavaScript/Client-Side RunKit Execution
- **`app/assets/builds/articleForm.js`:** Removed `handleRunkitPreview()` function and activation calls
- **`app/assets/builds/baseInitializers.js`:** Removed `activateRunkitTags` initialization
- **`app/javascript/initializers/initializeCommentPreview.js`:** Removed RunKit preview activation

### RunKit Service Integrations
- No direct RunKit service calls (they were in client-side JS only)
- External RunKit API dependencies eliminated

---

## Backward Compatibility Preserved

### Legacy `{% runkit %}` Tags
- The Liquid tag `{% runkit %}` is **still registered** for backward compatibility
- Old `{% runkit %}...{% endrunkit %}` blocks render a static fallback instead of executing
- Users seeing old content with RunKit tags will see code blocks with a clear message: *"This code block is no longer available. The original code is shown below."*

### Baked HTML `.runkit-element` Class
- Legacy articles/comments with saved RunKit HTML (`.runkit-element`) are still processed
- The `.runkit-element` class selector in models handles old baked HTML
- These are replaced with the same generic fallback at render time

---

## What Still References RunKit

These references are **intentional and necessary**:

### 1. Liquid Tag Registration
```ruby
# app/liquid_tags/legacy_code_tag.rb
Liquid::Template.register_tag("runkit", LegacyCodeTag)
```
**Reason:** Allows old `{% runkit %}` tags in markdown to still be processed and render gracefully.

### 2. Legacy HTML Selectors
```ruby
# app/models/article.rb & app/models/comment.rb
fragment.css('.runkit-element').each do |element|
```
**Reason:** Articles and comments stored before removal have `.runkit-element` in their baked HTML. These are transformed to fallback HTML at render time.

### 3. Test Fixtures
```
spec/fixtures/files/article_with_legacy_code_tag.txt
spec/fixtures/files/article_with_legacy_code_tag_with_preamble.txt
```
**Reason:** Test data contains `{% runkit %}` markup to validate fallback rendering works correctly.

### 4. Test Helpers
```ruby
# spec/support/legacy_code_tag_context.rb
{% runkit %}
console.log("comment")
{% endrunkit %}
```
**Reason:** Ensures specs can test that legacy code tags render properly as fallbacks.

---

## Validation & Testing

### Test Coverage
- ✅ Unit tests for `LegacyCodeTag` rendering
- ✅ System tests for article creation with legacy code tags
- ✅ System tests for comment creation with legacy code tags
- ✅ Test fixtures validate fallback HTML structure

### Manual Verification
- ✅ No `runkit` or `RunkitTag` class references in source code (excluding intentional backward compatibility)
- ✅ No active RunKit execution paths
- ✅ No user-facing RunKit branding in fallback messages
- ✅ CSS class naming is generic: `ltag-legacy-code-fallback`
- ✅ Locale keys are generic: `legacy_code_tag.invalid_tag`
- ✅ Old files physically deleted from workspace
- ✅ File structure is clean and consistent

---

## Breaking Changes: NONE ✅

**Important:** This removal maintains **full backward compatibility** with existing content:
- Old articles with `{% runkit %}` tags: Still render (as fallback blocks)
- Old comments with `{% runkit %}` tags: Still render (as fallback blocks)
- Users do not need to migrate content
- No database migrations required

---

## What Happens to Old RunKit Content?

### Before Removal (Interactive)
```html
{% runkit %}
const msg = "Hello";
console.log(msg);
{% endrunkit %}
```
↓ Rendered as interactive widget in RunKit environment

### After Removal (Static Fallback)
```html
<div class="ltag-legacy-code-fallback crayons-notice crayons-notice--warning">
  <p>This code block is no longer available. The original code is shown below.</p>
  <pre class="ltag-legacy-code-fallback__code"><code>
  const msg = "Hello";
  console.log(msg);
  </code></pre>
</div>
```
↓ Renders as read-only code block with warning message

---

## Files Modified Summary

| File | Change | Status |
|------|--------|--------|
| `app/liquid_tags/legacy_code_tag.rb` | Renamed from `runkit_tag.rb`, class renamed to `LegacyCodeTag` | ✅ |
| `app/models/article.rb` | Method renamed to `replace_legacy_code_html`, class reference updated | ✅ |
| `app/models/comment.rb` | Method renamed to `replace_legacy_code_html`, class reference updated | ✅ |
| `config/locales/liquid_tags/en.yml` | Locale key `legacy_code_tag.invalid_tag` added | ✅ |
| `config/locales/liquid_tags/fr.yml` | Locale key `legacy_code_tag.invalid_tag` added | ✅ |
| `config/locales/liquid_tags/pt.yml` | Locale key `legacy_code_tag.invalid_tag` added | ✅ |
| `spec/liquid_tags/legacy_code_tag_spec.rb` | Renamed from `runkit_tag_spec.rb`, spec class updated | ✅ |
| `spec/support/legacy_code_tag_context.rb` | Renamed from `runkit_tag_context.rb`, helpers renamed | ✅ |
| `spec/system/comments/user_fills_out_comment_spec.rb` | Test context and helpers updated | ✅ |
| `spec/system/articles/user_creates_an_article_spec.rb` | Test context and fixture variables updated | ✅ |
| `spec/fixtures/files/article_with_legacy_code_tag.txt` | Renamed from `article_with_runkit_tag.txt` | ✅ |
| `spec/fixtures/files/article_with_legacy_code_tag_with_preamble.txt` | Renamed from `article_with_runkit_tag_with_preamble.txt` | ✅ |

---

## Removal Details by Category

### ✂️ Deleted Files (6)
- `app/liquid_tags/runkit_tag.rb`
- `app/views/liquids/_runkit.html.erb`
- `spec/liquid_tags/runkit_tag_spec.rb`
- `spec/support/runkit_tag_context.rb`
- `spec/fixtures/files/article_with_runkit_tag.txt`
- `spec/fixtures/files/article_with_runkit_tag_with_preamble.txt`

### 📝 Renamed Files (6)
- `runkit_tag.rb` → `legacy_code_tag.rb`
- `runkit_tag_spec.rb` → `legacy_code_tag_spec.rb`
- `runkit_tag_context.rb` → `legacy_code_tag_context.rb`
- `article_with_runkit_tag.txt` → `article_with_legacy_code_tag.txt`
- `article_with_runkit_tag_with_preamble.txt` → `article_with_legacy_code_tag_with_preamble.txt`

### 🔧 Modified Files (10)
- `app/models/article.rb` (method rename, class reference update)
- `app/models/comment.rb` (method rename, class reference update)
- `config/locales/liquid_tags/en.yml`
- `config/locales/liquid_tags/fr.yml`
- `config/locales/liquid_tags/pt.yml`
- `spec/system/comments/user_fills_out_comment_spec.rb`
- `spec/system/articles/user_creates_an_article_spec.rb`
- Generated assets cleaned of RunKit activation (previous cleanup)

---

## Helpful Notes

### For Developers

1. **No Database Changes Required**
   - Existing `processed_html` columns with RunKit content are transformed at render time
   - No migration needed; backward compatible

2. **Locale Keys Are Generic Now**
   - Error messages no longer mention "RunKit"
   - All references use `legacy_code_tag` naming convention
   - Easier to repurpose for other deprecated code blocks in future

3. **Backward Compatible Registration**
   - `Liquid::Template.register_tag("runkit", LegacyCodeTag)` keeps old markdown working
   - Users don't need to update their content

4. **CSS Classes Are Generic**
   - `ltag-legacy-code-fallback` can be styled separately from other error notices
   - Easy to customize appearance if needed

### For Content Creators

- Old articles with `{% runkit %}` tags will continue to display your code
- The code will show in a read-only block with a note: *"This code block is no longer available"*
- No action needed; content is preserved

### For Maintainers

- If new deprecated code blocks need adding: Use the `LegacyCodeTag` pattern as a template
- All RunKit branding is gone from source (except intentional backward compatibility)
- Tests verify fallback rendering works for both articles and comments

---

## Verification Checklist

- ✅ No `RunkitTag` class exists in codebase
- ✅ No `runkit` file names in `app/liquid_tags/` or `spec/`
- ✅ No active JavaScript execution of RunKit
- ✅ No RunKit service calls or API integration
- ✅ All user-facing text updated (CSS, locales, test descriptions)
- ✅ Backward compatibility maintained (`{% runkit %}` still processes)
- ✅ Legacy HTML (`.runkit-element`) still handled
- ✅ Test fixtures and helpers renamed/updated
- ✅ Locale files updated for all supported languages (EN, FR, PT)
- ✅ Zero breaking changes for existing content

---

## References

- **Liquid Tag System:** `config/initializers/liquid.rb` (auto-loads all `app/liquid_tags/*.rb`)
- **Legacy HTML Processing:** `app/models/article.rb#processed_html_final`, `app/models/comment.rb#processed_html_final`
- **Fallback Rendering:** `app/liquid_tags/legacy_code_tag.rb#fallback_html`

---

**RemovalStatus:** ✅ COMPLETE  
**Backward Compatibility:** ✅ PRESERVED  
**Tests:** ✅ PASSING  
**Breaking Changes:** ❌ NONE
