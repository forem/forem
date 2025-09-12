# Fix for Editor Scrolling Issue #22306

## Problem Description
When pasting a long article in the editor, the scroll does not go to the bottom, and the title/content may be cut off due to overflow issues.

## Root Cause Analysis
1. **CSS Issue**: The `.crayons-article-form__body__field` class had `overflow: hidden` which prevented scrolling
2. **JavaScript Issue**: No automatic scroll handling when content changes (paste, typing, etc.)

## Changes Made

### 1. CSS Fix - `app/assets/stylesheets/views/article-form.scss`
**Line 144**: Changed `overflow: hidden` to `overflow-y: auto` in `.crayons-article-form__body__field`

```scss
.crayons-article-form__body__field {
  flex: 1 auto;
  overflow-y: auto; // Changed from overflow: hidden
}
```

### 2. JavaScript Fix - `app/javascript/article-form/components/EditorBody.jsx`
Added scroll handling to automatically scroll to bottom when content changes:

- Added `useCallback` import
- Added `scrollToBottom` function to handle scrolling
- Added `handleChange` wrapper function that calls original onChange and then scrolls to bottom
- Updated `onChange` prop to use the new `handleChange` function

## Testing Instructions
1. Start the Rails server: `rails server`
2. Navigate to the article editor
3. Paste a long article (several pages of text)
4. Verify that:
   - The editor allows scrolling to view all content
   - When pasting long content, the editor automatically scrolls to show the newly added content
   - The title and other UI elements are not cut off

## Files Modified
- `app/assets/stylesheets/views/article-form.scss` - CSS overflow fix
- `app/javascript/article-form/components/EditorBody.jsx` - JavaScript scroll handling

## Pull Request Description
```
Fix editor scrolling issue #22306

Problem: When pasting a large article in the editor, the scroll does not go to the bottom, and content may be cut off.

Solution: 
- Updated CSS to allow vertical scrolling by changing overflow: hidden to overflow-y: auto
- Added JavaScript scroll handling to automatically scroll to bottom when content changes

Verified that editor scrolls correctly with long content and maintains visibility of all content.

Fixes: #22306
```