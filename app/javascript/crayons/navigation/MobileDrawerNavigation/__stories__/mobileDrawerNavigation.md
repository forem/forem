## MobileDrawerNavigation

The MobileDrawerNavigation component is intended to be used on small
(mobile-sized) screens only. It can be used as an alternative to the larger
navigation tab component.

The component is responsible for showing:

- The heading of the currently selected page
- A navigation dialog with the given links

This component is best placed at the top of a page. The dialog utilizes
`<MobileDrawer />`, and will appear from the bottom of the screen.

### MobileDrawerNavigation Accessibility

The MobileDrawerNavigation component requires a `navigationTitle` prop which
will be used for:

- The activating button for the navigation dialog
- The label of the navigation dialog
- The label of the navigation element containing the links

This helps ensure accessible element names are surfaced to all users.

The component also requires a `headingLevel` prop which is used to determine the
HTML element used for the displayed current page title (e.g. `1` will render an
`h1`). Appropriate consideration should be given to which heading level is
semantically correct for the location the component is rendered.
