## Navigation: Tabs

Use tabs as 2nd level navigation or filtering options.

### Notes

In order to prevent layout shift on tab change the `data-text` attribute was
added. The content of `data-text` should be the same as the text entered into
the body of the tab, this allows us to render a bold, but hidden, version of the
text to base the tab's size on.

_Because of this if you intend to have more than one element in your tab you
must wrap it in a span._
