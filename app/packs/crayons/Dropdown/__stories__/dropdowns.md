## Dropdowns

Dropdowns should have position relative to it’s trigger. They can be used for
some 2nd level navigations, contextual configurations, etc...

Dropdowns should not be bigger than 320px. Dropdown default padding should be
dependent on width:

- < 250px: 16px 251 - 320px: 24px

FYI: Dropdowns use “Box” component as background, with Level 3 elevation.

### Dropdown accessibility

#### Preact implementation

The Preact Dropdown component has the below accessibility features baked-in. To
make sure this works correctly, you need only pass the appropriate
`triggerButtonId` and `dropdownContentId` to identify the button which controls
the dropdown, and the dropdown content div itself. All required aria attributes
and click handlers will be initialized by the Preact component.

#### HTML implementation

When creating a dropdown outside of the Preact code, use the utility method
`initializeDropdown` in `@utilities/dropdownUtils`. This will attach all the
necessary aria attributes and click handlers.

#### Expected interaction pattern

When either the Preact component is used with appropriate props, or the HTML
variant is initialized, all Crayons dropdowns should conform to the following
behaviors:

- The dropdown opens and closes with a mouse click on the trigger button
- The trigger button can be focused by keyboard, and pressing Enter opens and
  closes the dropdown
- Pressing Escape closes the dropdown when it's open
- Clicking anywhere outside of the dropdown closes it if it is open
- If activated by keyboard, visible focus is transferred to the first
  interactive item (e.g. link) in the dropdown when it opens
- If a user closes the dropdown by pressing Escape, focus is returned back to
  the button that opened it
- If a user closes the dropdown by clicking outside, focus is returned back to
  the button that opened it _unless_ they clicked on some other interactive item
  (e.g. they clicked a button that exists elsewhere on the page)
- When the dropdown is open, if you use the Tab key or Shift + Tab (moves
  backwards) and tab past the first or last interactive item in the dropdown,
  the dropdown should close
- The button which activates the dropdown should have the attributes:
  `aria-expanded`, `aria-haspopup="true"`,
  `aria-controls="<dropdown content id>"`
- `aria-expanded` should be "true" when the dropdown is visible, and "false"
  otherwise
