# Internationalization (i18n) Implementation Guide

## Overview

This document captures the comprehensive scope and lessons learned from implementing Brazilian Portuguese (pt) internationalization throughout the Forem codebase, alongside existing English (en) and French (fr) translations.

## 📊 Implementation Scope

### Files Modified: 15+ Core Files

#### **Locale Files (8 files)**
- `config/locales/helpers/pt.yml` - Helper translations
- `config/locales/helpers/en.yml` - Updated to match structure
- `config/locales/helpers/fr.yml` - Updated to match structure
- `config/locales/controllers/admin/pt.yml` - Admin controller translations
- `config/locales/kaminari.pt.yml` - Pagination translations
- `config/locales/liquid_tags/pt.yml` - Liquid tag translations
- `config/locales/services/pt.yml` - Service translations
- `config/locales/devise.fr.yml` - Created missing French Devise file

#### **Application Code (7 files)**
- `app/models/subforem.rb` - Added `default_locale` attr_accessor
- `app/controllers/admin/subforems_controller.rb` - Added locale parameter handling
- `app/views/admin/subforems/_form.html.erb` - Added locale picker dropdown
- `app/workers/subforems/create_from_scratch_worker.rb` - Added locale parameter
- `app/services/ai/community_copy.rb` - Added locale-specific prompts
- `app/services/ai/forem_tags.rb` - Added locale-specific prompts
- `app/services/ai/about_page_generator.rb` - Added locale-specific prompts

#### **Test Files (4 files)**
- `spec/models/subforem_spec.rb` - Updated method signatures
- `spec/requests/admin/subforems_spec.rb` - Updated expectations
- `spec/requests/admin/subforems_about_page_spec.rb` - Updated expectations
- `spec/workers/subforems/create_from_scratch_worker_spec.rb` - Updated method calls

#### **Tool Scripts (4 files)**
- `bin/locale_file_lookup` - Enhanced locale analysis tool
- `bin/create_missing_locales` - Created missing locale files
- `bin/fix_helpers_structure` - Fixed nested structure issues
- `bin/add_missing_helper_keys` - Added missing helper keys

#### **Documentation (3 files)**
- `docs/portuguese_internationalization_summary.md` - Implementation summary
- `docs/locale_analysis.md` - Locale coverage analysis
- `docs/README.md` - Documentation index

## 🚨 Critical Gotchas & Lessons Learned

### 1. **Interpolation Consistency is CRITICAL**

**Issue**: 34 inconsistent interpolations found initially
**Root Cause**: Portuguese translations missing interpolation variables present in English versions

**Examples**:
```yaml
# ❌ Wrong - Missing interpolation
pt: "Grupo criado com sucesso!"
en: "Successfully created group: %{group}"

# ✅ Correct - Matching interpolations
pt: "Grupo criado com sucesso: %{group}"
en: "Successfully created group: %{group}"
```

**Lesson**: Always ensure interpolation variables match exactly between locales.

### 2. **YAML Structure Must Be Identical**

**Issue**: Deeply nested structures caused test failures
**Root Cause**: Inconsistent nesting between `en`, `fr`, and `pt` files

**Example**:
```yaml
# ❌ Wrong - Inconsistent nesting
en:
  helpers:
    label:
      video: "Video"
pt:
  helpers:
    settings_helper:
      social_link_helper:
        label:
          video: "Vídeo"

# ✅ Correct - Identical structure
en:
  helpers:
    label:
      video: "Video"
pt:
  helpers:
    label:
      video: "Vídeo"
```

**Lesson**: Maintain identical YAML structure across all locale files.

### 3. **Method Signature Changes Require Test Updates**

**Issue**: Worker method signature changed from 5 to 6 parameters
**Impact**: All tests calling the worker needed updates

**Example**:
```ruby
# ❌ Old signature
Subforems::CreateFromScratchWorker.perform_async(id, brain_dump, name, logo_url, bg_image_url)

# ✅ New signature
Subforems::CreateFromScratchWorker.perform_async(id, brain_dump, name, logo_url, bg_image_url, default_locale)
```

**Lesson**: When changing method signatures, update ALL related tests immediately.

### 4. **Mock Return Values Matter**

**Issue**: Tests failed because mocked methods returned `nil` instead of expected values
**Root Cause**: `Settings::Community.set_community_name` mock didn't return the name

**Example**:
```ruby
# ❌ Wrong - Returns nil
allow(Settings::Community).to receive(:set_community_name)

# ✅ Correct - Returns expected value
allow(Settings::Community).to receive(:set_community_name).and_return(name)
```

**Lesson**: Ensure mocks return appropriate values, not just `nil`.

### 5. **Locale File Organization is Complex**

**Issue**: Locale files are scattered across multiple directories
**Structure**:
```
config/locales/
├── *.yml (main locale files)
├── controllers/
│   ├── admin/
│   └── api/
├── helpers/
├── liquid_tags/
├── services/
├── devise.*.yml
├── kaminari.*.yml
└── devise_invitable.*.yml
```

**Lesson**: Use the `bin/locale_file_lookup` tool to identify all files that need updates.

### 6. **AI Service Integration Requires Careful Prompt Engineering**

**Issue**: AI services needed locale-specific instructions
**Solution**: Added `get_locale_instruction` methods with specific language requirements

**Example**:
```ruby
def get_locale_instruction
  case @locale
  when 'pt'
    "LANGUAGE REQUIREMENT: Generate ALL content in Brazilian Portuguese..."
  when 'fr'
    "LANGUAGE REQUIREMENT: Generate ALL content in French..."
  else
    "LANGUAGE REQUIREMENT: Generate ALL content in English..."
  end
end
```

**Lesson**: AI content generation requires explicit language instructions in prompts.

## 🛠️ Essential Tools Created

### 1. **`bin/locale_file_lookup`**
- Analyzes locale file coverage
- Identifies missing files
- Supports multiple locales
- CLI options for different use cases

### 2. **`bin/create_missing_locales`**
- Creates missing locale files from English templates
- Filters out irrelevant directories
- Supports dry-run mode

### 3. **`bin/fix_helpers_structure`**
- Fixes nested structure issues
- Removes duplicate keys
- Maintains consistent YAML structure

### 4. **`bin/add_missing_helper_keys`**
- Adds missing top-level sections
- Adds missing nested keys
- Compares against English reference

## 📋 Pre-Implementation Checklist

Before starting any i18n work:

1. **Run `bin/locale_file_lookup`** to identify all affected files
2. **Check interpolation consistency** with `i18n-tasks check-consistent-interpolations`
3. **Identify all test files** that will need updates
4. **Plan method signature changes** and their impact
5. **Create backup of current state** before making changes
6. **Test incrementally** after each major change

## 🔄 Implementation Workflow

### Phase 1: Analysis
1. Use `bin/locale_file_lookup` to identify scope
2. Run i18n tests to identify current issues
3. Document all files that need changes

### Phase 2: Core Implementation
1. Create/update locale files
2. Fix interpolation issues
3. Ensure YAML structure consistency
4. Update application code

### Phase 3: Testing
1. Update all related test files
2. Fix mock return values
3. Run comprehensive test suite
4. Verify i18n compliance

### Phase 4: Validation
1. Run `i18n-tasks check-consistent-interpolations`
2. Test application functionality
3. Verify AI service integration
4. Document changes

## 🎯 Key Success Metrics

- **Zero interpolation inconsistencies**
- **All tests passing**
- **Identical YAML structure across locales**
- **Proper method signature updates**
- **Comprehensive test coverage**

## 🚀 Future i18n Work Recommendations

1. **Always start with `bin/locale_file_lookup`** to understand scope
2. **Use the created tools** for automation and consistency
3. **Test incrementally** to catch issues early
4. **Document changes** for future reference
5. **Maintain identical structure** across all locale files
6. **Consider AI service integration** when adding new locales

## 📚 Related Documentation

- [Portuguese Internationalization Summary](portuguese_internationalization_summary.md)
- [Locale Analysis](locale_analysis.md)
- [i18n Tools Usage Guide](portuguese_internationalization_summary.md#i18n-tools)

---

*This guide should be updated with each new i18n implementation to capture additional lessons learned and best practices.*
