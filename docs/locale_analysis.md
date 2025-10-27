# Locale File Analysis for Forem Internationalization

## Overview
This document provides a comprehensive analysis of the current state of internationalization in the Forem project, specifically focusing on Portuguese (pt) and French (fr) translations.

## Current Coverage Statistics
- **English files found**: 74
- **Coverage**: 68.24% (101 out of 148 expected equivalents present)
- **Missing equivalents**: 47 files

## Analysis Results

### ✅ **Completed Portuguese Translations**
The following Portuguese locale files have been successfully created:

#### Main Locale Files
- `config/locales/pt.yml` - Main Portuguese locale file
- `config/locales/devise.pt.yml` - Devise authentication translations
- `config/locales/kaminari.pt.yml` - Pagination translations
- `config/locales/devise_invitable.pt.yml` - Devise invitation translations

#### Controllers
- `config/locales/controllers/pt.yml` - General controller translations
- `config/locales/controllers/admin/pt.yml` - Admin controller translations
- `config/locales/controllers/api/pt.yml` - API controller translations

#### Views
- `config/locales/views/main/pt.yml` - Main view translations
- `config/locales/views/articles/pt.yml` - Article view translations
- `config/locales/views/settings/pt.yml` - Settings view translations
- `config/locales/views/admin/pt.yml` - Admin view translations
- `config/locales/views/users/pt.yml` - User view translations
- `config/locales/views/comments/pt.yml` - Comment view translations
- `config/locales/views/dashboard/pt.yml` - Dashboard view translations
- `config/locales/views/tags/pt.yml` - Tag view translations
- `config/locales/views/notifications/pt.yml` - Notification view translations
- `config/locales/views/editor/pt.yml` - Editor view translations

#### Other Components
- `config/locales/helpers/pt.yml` - Helper translations
- `config/locales/mailers/pt.yml` - Mailer translations
- `config/locales/languages/pt.yml` - Language translations
- `config/locales/concerns/pt.yml` - Concern translations
- `config/locales/decorators/pt.yml` - Decorator translations
- `config/locales/utils/pt.yml` - Utility translations
- `config/locales/validators/pt.yml` - Validator translations
- `config/locales/services/pt.yml` - Service translations
- `config/locales/misc/pt.yml` - Miscellaneous translations
- `config/locales/liquid_tags/pt.yml` - Liquid tag translations
- `config/locales/lib/pt.yml` - Library translations

### ❌ **Missing Portuguese Translations**

#### View Files (High Priority)
The following view files need Portuguese translations:

**Credits Views:**
- `app/views/credits/_pricing.pt.html.erb`
- `app/views/credits/_purchase_faq.pt.html.erb`

**Pages Views:**
- `app/views/pages/_coc_text.pt.html.erb`
- `app/views/pages/_editor_frontmatter_help.pt.html.erb`
- `app/views/pages/_editor_guide_h3.pt.html.erb`
- `app/views/pages/_editor_guide_text.pt.html.erb`
- `app/views/pages/_editor_liquid_help.pt.html.erb`
- `app/views/pages/_editor_markdown_help.pt.html.erb`
- `app/views/pages/_liquid_tag_section_intro.pt.html.erb`
- `app/views/pages/_placeholder.pt.html.erb`
- `app/views/pages/_privacy_text.pt.html.erb`
- `app/views/pages/_supported_nonurl_embeds_list.pt.html.erb`
- `app/views/pages/_supported_url_embeds_list.pt.html.erb`
- `app/views/pages/_terms_text.pt.html.erb`
- `app/views/pages/_v1_editor_guide_preamble.pt.html.erb`
- `app/views/pages/about.pt.html.erb`
- `app/views/pages/about_listings.pt.html.erb`
- `app/views/pages/bounty.pt.html.erb`
- `app/views/pages/code_of_conduct.pt.html.erb`
- `app/views/pages/community_moderation.pt.html.erb`
- `app/views/pages/contact.pt.html.erb`
- `app/views/pages/editor_guide.pt.html.erb`
- `app/views/pages/faq.pt.html.erb`
- `app/views/pages/forbidden.pt.html.erb`
- `app/views/pages/markdown_basics.pt.html.erb`
- `app/views/pages/post_a_job.pt.html.erb`
- `app/views/pages/privacy.pt.html.erb`
- `app/views/pages/publishing_from_rss_guide.pt.html.erb`
- `app/views/pages/report_abuse.pt.html.erb`
- `app/views/pages/show.pt.html.erb`
- `app/views/pages/tag_moderation.pt.html.erb`
- `app/views/pages/terms.pt.html.erb`

#### Locale Files (Medium Priority)
The following locale files need Portuguese translations:

- `config/locales/views/actions/pt.yml`
- `config/locales/views/auth/pt.yml`
- `config/locales/views/credits/pt.yml`
- `config/locales/views/feedback/pt.yml`
- `config/locales/views/liquids/pt.yml`
- `config/locales/views/listings/pt.yml`
- `config/locales/views/manager/pt.yml`
- `config/locales/views/misc/pt.yml`
- `config/locales/views/moderations/pt.yml`
- `config/locales/views/organizations/pt.yml`
- `config/locales/views/podcasts/pt.yml`
- `config/locales/views/reactions/pt.yml`
- `config/locales/views/stories/pt.yml`
- `config/locales/views/subforems/pt.yml`

### ❌ **Missing French Translations**
The following French translations are missing:
- `config/locales/devise.fr.yml`

## Recommendations

### Priority Order for Completion

1. **High Priority**: View files (especially pages and credits)
   - These are user-facing and directly impact the user experience
   - Start with the most commonly accessed pages (about, privacy, terms, faq)

2. **Medium Priority**: Locale files in `config/locales/views/`
   - These contain form labels, messages, and UI text
   - Important for form interactions and user feedback

3. **Low Priority**: French translations
   - Only one file missing (`config/locales/devise.fr.yml`)
   - Can be addressed after Portuguese is complete

### Implementation Strategy

1. **Use the locale file lookup script** to track progress:
   ```bash
   bin/locale_file_lookup --locales=pt,fr
   ```

2. **Create Portuguese translations** by copying English files and translating content:
   ```bash
   # Example for a view file
   cp app/views/pages/about.en.html.erb app/views/pages/about.pt.html.erb
   # Then edit the Portuguese file to translate the content
   ```

3. **Use Brazilian Portuguese** dialect as specified in the original requirements

4. **Maintain consistency** with existing Portuguese translations in terms of terminology and style

5. **Test translations** by running the i18n test:
   ```bash
   bundle exec rspec spec/i18n_spec.rb:15
   ```

## Tools Available

### Locale File Lookup Script
The `bin/locale_file_lookup` script provides:
- **Basic analysis**: `bin/locale_file_lookup --locales=pt,fr`
- **Complete analysis**: `bin/locale_file_lookup --check-all`
- **JSON output**: `bin/locale_file_lookup --json`
- **Verbose output**: `bin/locale_file_lookup --verbose`

### Usage Examples
```bash
# Check current coverage
bin/locale_file_lookup --locales=pt,fr

# Get detailed analysis in JSON format
bin/locale_file_lookup --locales=pt,fr --json

# Check all locale files for missing equivalents
bin/locale_file_lookup --check-all

# Show help
bin/locale_file_lookup --help
```

## Next Steps

1. **Start with high-priority view files** (pages and credits)
2. **Create missing locale files** in `config/locales/views/`
3. **Add French Devise translations** (`config/locales/devise.fr.yml`)
4. **Run tests** to ensure all translations are working correctly
5. **Use the lookup script** to verify completion

## Notes

- The script successfully identified 74 English locale files
- Current coverage is 68.24%, which is a good foundation
- Most missing files are view templates and locale files
- The core functionality (controllers, models, helpers) is well covered
- The script can be used to track progress as new translations are added
