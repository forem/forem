## Mention autocomplete

The `MentionAutocompleteTextArea` component uses the [Reach UI Combobox](https://reach.tech/combobox/) under the hood. It works by _replacing_ the textarea you pass in props with one enhanced with the `@mention` functionality.

The autocomplete will begin fetching suggestions once a user has typed `@` plus at least two characters. A user&apos;s selection is confirmed when they either:

- Click on a search option
- Hit enter on a search option
- Click away from the dropdown
- Enter space to move away from the autocomplete

### Mention autocomplete accessibility

The component replaces the given textarea with one generated using [Reach UI Combobox](https://reach.tech/combobox/). The underlying behavior then conforms to the [WAI_ARIA guidelines on comboboxes](https://www.w3.org/TR/wai-aria-practices-1.2/#combobox).

An `aria-live` region communicates to a screen reader user when the list has been populated with suggestions.

Please note: When using the `MentionAutocompleteTextArea`, you must have either an `aria-labelledby` or `aria-label` attribute on the textarea you pass as a prop. These attributes are copied across to the Reach UI Combobox input, ensuring it is labelled correctly for accessibility.
