## Navigation: Tabs

Use tabs as 2nd level navigation or filtering options. These tabs are generally
used in Forem as collections of **links**. As such, the `crayons-tabs` class
should be used on a `nav` element and should wrap a list of links.

### Accessibility

When using Crayons Tabs for lists of links, ensure that:

- The `crayons-tabs` class is used on a `nav` element
- The `nav` element has an `aria-label` (e.g.
  `aria-label="View posts by period"`)
- All links inside the `nav` element are contained in list items (`<li>`) in an
  unordered list (`<ul>`)
- The currently active link has the attribute `aria-current="page"`, which tells
  screen reader users which link is currently active
