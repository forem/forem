## Navigation: Tabs

Use tabs as second level navigation or filtering options, either links (if the
page will change on click) or buttons (if a new UI is to be presented without
the URL changing).

As these tabs are used for navigation, the `crayons-tabs` class should be used
on a `nav` element, and should wrap a list of navigation links/buttons.

### Accessibility

When using Crayons Tabs for lists of links, ensure that:

- The `crayons-tabs` class is used on a `nav` element
- The `nav` element has an `aria-label` (e.g.
  `aria-label="View posts by period"`)
- All links/buttons inside the `nav` element are contained in list items
  (`<li>`) in an unordered list (`<ul>`)
- The currently active link/button has the attribute `aria-current="page"`,
  which tells screen reader users which link/button is currently active
