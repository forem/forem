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

### Notes

In order to prevent layout shift on tab change the `data-text` attribute was
added. The content of `data-text` should be the same as the text entered into
the body of the tab, this allows us to render a bold, but hidden, version of the
text to base the tab's size on.

_Because of this if you intend to have more than one element in your tab you
must wrap it in a span._
