## Mention autocomplete

The mention autocomplete component uses the [Reach UI Combobox](https://reach.tech/combobox/) under the hood. It can be used for searching for users by username by passing in a reference to the relevant text area.

The autocomplete will begin fetching suggestions once a user has type '@' plus at least two characters. A user's selection is confirmed when they either:

- Click on a search option
- Hit enter on a search option
- Click away from the dropdown
- Enter space to move away from the autocomplete

### Mention autocomplete accessibility

The component works by switching focus to an invisible combobox input once the user types @. Focus is sent back to the original textarea when selection is completed. The underlying [Reach UI Combobox](https://reach.tech/combobox/) behavior conforms to the [WAI_ARIA guidelines on comboboxes](https://www.w3.org/TR/wai-aria-practices-1.2/#combobox).
