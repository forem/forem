# Fix for Editor Scrolling and Title Clipping Issues #22306

## Problem Description
1. **Double Scrollbars**: When pasting a long article in the editor, there were two scrollbars - one on the container and one on the textarea field
2. **Title Clipping**: The title field was being clipped on Windows 11 systems due to improper container height calculations
3. **Automatic Scrolling**: Previous fix added unwanted automatic scroll-to-bottom behavior

## Root Cause Analysis
1. **Double Scrollbars**: Both `.crayons-article-form__content` and `.crayons-article-form__body__field` had `overflow-y: auto`
2. **Title Clipping**: Fixed height containers didn't properly accommodate dynamic title heights on Windows
3. **AutoResize Conflict**: The `autoResize` prop on AutocompleteTriggerTextArea conflicted with container scrolling

## Changes Made

### 1. JavaScript Fix - `app/javascript/article-form/components/EditorBody.jsx`
- Removed `autoResize` prop from AutocompleteTriggerTextArea
- Removed automatic scroll-to-bottom behavior and related imports
- Simplified onChange handler to just call the original onChange prop

### 2. CSS Fix - `app/assets/stylesheets/views/article-form.scss`
**Container Scrolling**:
- Enhanced `.crayons-article-form__content` with proper scrollbar styling
- Added smooth scrolling and touch scrolling support
- Added custom scrollbar styling for better UX

**Body Field**:
- Removed `overflow-y: auto` from `.crayons-article-form__body__field`
- Set overflow to `visible` to prevent double scrollbars
- Added minimum height and disabled scrollbars on textarea
- Set proper flex properties for content growth

**Title Field**:
- Added overflow: visible to prevent clipping
- Enhanced textarea styling for better Windows compatibility
- Improved line-height for better text rendering

## Testing Instructions
1. Start the Rails server: `rails server`
2. Navigate to the article editor (`/new`)
3. **Test Title Clipping**:
   - Type a long title in the title field
   - Verify the title is fully visible and not clipped
4. **Test Scrolling**:
   - Paste a very long article (several pages of text) into the editor
   - Verify there is only ONE scrollbar (on the main content container)
   - Verify you can scroll through all the content smoothly
   - Test on Windows 11 with Chrome to ensure no clipping occurs
5. **Test Normal Usage**:
   - Type normally in both title and content areas
   - Verify no unwanted automatic scrolling occurs
   - Verify the editor behaves naturally

## Files Modified
- `app/javascript/article-form/components/EditorBody.jsx` - Removed autoResize and auto-scroll behavior
- `app/assets/stylesheets/views/article-form.scss` - Fixed double scrollbars and title clipping

## Pull Request Description
```
Fix double scrollbars and title clipping in editor #22306

Problem: 
1. Editor showed two scrollbars when content was long
2. Title field was clipped on Windows 11
3. Previous fix added unwanted auto-scroll behavior

Solution:
- Removed autoResize from textarea to prevent conflict with container scrolling
- Fixed CSS to have single, properly styled scrollbar on main container
- Enhanced title field styling to prevent clipping on Windows
- Removed automatic scroll-to-bottom behavior

Tested on Windows 11 Chrome - both issues resolved, only one scrollbar appears.

Fixes: #22306
```