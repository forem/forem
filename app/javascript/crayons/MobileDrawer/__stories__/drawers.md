## MobileDrawers

MobileDrawers are intended to be used in small screen sizes only (i.e. for
mobile UI variants), and always appear from the bottom of the viewport. The
button which triggers the MobileDrawer may be located anywhere on the page.

MobileDrawer content should always include at least one interactive item (e.g.
button, link) to make sure focus may be transferred to the new content.

### MobileDrawer accessibility

The MobileDrawer is essentially a
[modal dialog](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/dialog_role).
A `title` should be passed in props to properly label the dialog, and at least
one interactive item should be present in the inner content.

The MobileDrawer component utilises the `focus-trap` library to ensure that:

- When the drawer is opened, focus is transferred to the first interactive item
  in that drawer
- When the drawer is closed, focus is transferred back to the button that
  activated the drawer
- While the drawer is open, focus is trapped inside so that when a user presses
  the Tab key, interactive items behind the drawer are not focused
- When the drawer is open, pressing the Escape key will close it
