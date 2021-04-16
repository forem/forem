## Dropdowns

Dropdowns should have position relative to it’s trigger. They can be used for
some 2nd level navigations, contextual configurations, etc...

Dropdowns should not be bigger than 320px. Dropdown default padding should be
dependent on width:

- < 250px: 16px 251 - 320px: 24px

FYI: Dropdowns use “Box” component as background, with Level 3 elevation.

### Dropdown accessibility

When a dropdown of options is opened, focus should be sent to the first
interactive item inside the dropdown content. When the dropdown is closed, focus
should return to the activator button. If there are no interactive items,
consider using an `aria-live` region to ensure the new content is announced to
screen-reader users when the dropdown appears.

A user should be able to open and close the dropdown by keyboard (e.g. using
Enter and Escape), and appropriate `aria` attributes (e.g. `aria-haspopup`) should be used
to indicate the relationship between the activator button and the dropdown
content.
