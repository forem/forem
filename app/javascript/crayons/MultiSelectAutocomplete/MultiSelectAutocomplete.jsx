/* eslint-disable jsx-a11y/interactive-supports-focus, jsx-a11y/role-has-required-aria-props */
// Disabled due to the linter being out of date for combobox role: https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/issues/789
import { h, Fragment } from 'preact';
import { useEffect, useRef, useReducer } from 'preact/hooks';
import { DefaultSelectionTemplate } from './DefaultSelectionTemplate';

const KEYS = {
  UP: 'ArrowUp',
  DOWN: 'ArrowDown',
  ENTER: 'Enter',
  ESCAPE: 'Escape',
  DELETE: 'Backspace',
  COMMA: ',',
  SPACE: ' ',
};

const ALLOWED_CHARS_REGEX = /([a-zA-Z0-9])/;

const PLACEHOLDER_SELECTIONS_MADE = 'Add another...';

const reducer = (state, action) => {
  switch (action.type) {
    case 'setSelectedItems':
      return {
        ...state,
        selectedItems: action.payload,
        suggestions: [],
        activeDescendentIndex: null,
      };
    case 'setSuggestions':
      return {
        ...state,
        suggestions: action.payload,
        activeDescendentIndex: null,
      };
    case 'updateEditState':
      return {
        ...state,
        editValue: action.payload.editValue,
        inputPosition: action.payload.inputPosition,
        forceInputFocus: action.payload.forceInputFocus,
      };
    case 'setActiveDescendentIndex':
      return { ...state, activeDescendentIndex: action.payload };
    case 'setIgnoreBlur':
      return { ...state, ignoreBlur: action.payload };
    case 'setForceInputFocus':
      return { ...state, forceInputFocus: action.payload };
    default:
      return state;
  }
};

// TODO: accept template for selected items, use current UI by default
// TODO: accept template for suggestions, use current UI by default
export const MultiSelectAutocomplete = ({
  labelText,
  fetchSuggestions,
  defaultValue = [],
  border = true,
  placeholder = 'Add...',
  maxSelections,
  onSelectionsChanged = () => {},
  SuggestionTemplate,
  SelectionTemplate = DefaultSelectionTemplate,
}) => {
  const [state, dispatch] = useReducer(reducer, {
    suggestions: [],
    selectedItems: defaultValue,
    inputPosition: null,
    editValue: null,
    activeDescendentIndex: null,
    ignoreBlur: false,
    forceInputFocus: false,
  });

  const {
    selectedItems,
    suggestions,
    inputPosition,
    editValue,
    activeDescendentIndex,
    ignoreBlur,
    forceInputFocus,
  } = state;

  const inputRef = useRef(null);
  const inputSizerRef = useRef(null);
  const selectedItemsRef = useRef(null);

  useEffect(() => {
    if (defaultValue.length > 0) {
      dispatch({ type: 'setSelectedItems', payload: defaultValue });
    }
  }, [defaultValue]);

  const handleInputBlur = () => {
    // Since the input is sometimes removed and rendered in a new location on blur, it's possible that inputRef.current may be null when we complete this check.
    const currentValue = inputRef.current ? inputRef.current.value : '';
    // The input will blur when user selects an option from the dropdown via mouse click. The ignoreBlur boolean lets us know we can ignore this event.
    if (!ignoreBlur && currentValue !== '') {
      selectByText({ textValue: currentValue, focusInput: false });
    } else {
      dispatch({ type: 'setSuggestions', payload: [] });
    }

    dispatch({ type: 'setIgnoreBlur', payload: false });
  };

  useEffect(() => {
    // editValue defaults to null when component is first rendered.
    // This ensures we do not autofocus the input before the user has started interacting with the component.
    if (editValue === null) return;

    const { current: input } = inputRef;
    if (input && inputPosition !== null) {
      // Entering 'edit' mode
      resizeInputToContentSize();

      input.value = editValue;
      const { length: cursorPosition } = editValue;
      input.focus();
      input.setSelectionRange(cursorPosition, cursorPosition);
      return;
    }

    // Exiting 'edit' mode, return focus to default input position
    input?.focus();
  }, [inputPosition, editValue]);

  useEffect(() => {
    if (forceInputFocus) {
      inputRef.current?.focus();
      dispatch({ type: 'setForceInputFocus', payload: false });
    }
  }, [forceInputFocus]);

  const selectByText = ({
    textValue,
    nextInputValue = '',
    focusInput = true,
  }) => {
    const matchingSuggestion = suggestions.find(
      (suggestion) => suggestion.name === textValue,
    );
    selectItem({
      selectedItem: matchingSuggestion
        ? matchingSuggestion
        : { name: textValue },
      nextInputValue,
      focusInput,
    });
  };

  const enterEditState = (editItem, editItemIndex) => {
    inputSizerRef.current.innerText = editItem.name;
    deselectItem(editItem);

    dispatch({
      type: 'updateEditState',
      payload: {
        editValue: editItem.name,
        inputPosition: editItemIndex,
        forceInputFocus: false,
      },
    });
  };

  const exitEditState = (nextInputValue = '') => {
    inputSizerRef.current.innerText = nextInputValue;

    // When a user has 'split' the value they were editing (e.g. by entering a space or comma), the remaining portion of the text
    // may now be edited if they have not exceeded the max selections
    const canEditNextInputValue =
      !maxSelections || selectedItems.length + 1 < maxSelections;

    dispatch({
      type: 'updateEditState',
      payload: {
        editValue: canEditNextInputValue ? nextInputValue : '',
        inputPosition:
          nextInputValue === '' || !canEditNextInputValue
            ? null
            : inputPosition + 1,
        forceInputFocus: true,
      },
    });
  };

  const resizeInputToContentSize = () => {
    const { current: input } = inputRef;
    if (input) {
      input.style.width = `${inputSizerRef.current.clientWidth}px`;
    }
  };

  const handleInputChange = async ({ target: { value } }) => {
    // When the input appears inline in "edit" mode, we need to dynamically calculate the width to ensure it occupies the right space
    // (an input cannot resize based on its text content). We use a hidden <span> to track the size.
    inputSizerRef.current.innerText = value;
    if (inputPosition !== null) {
      resizeInputToContentSize();
    }

    const results = await fetchSuggestions(value);
    // If no results, display current search term as an option
    if (results.length === 0 && value !== '') {
      results.push({ name: value });
    }

    dispatch({
      type: 'setSuggestions',
      payload: results.filter(
        (item) =>
          !selectedItems.some(
            (selectedItem) => selectedItem.name === item.name,
          ),
      ),
    });
  };

  const clearInput = () => {
    inputRef.current.value = '';
    dispatch({ type: 'setSuggestions', payload: [] });
  };

  const handleKeyDown = (e) => {
    const { selectionStart, value: currentValue } = inputRef.current;

    switch (e.key) {
      case KEYS.DOWN:
        e.preventDefault();

        if (
          activeDescendentIndex !== null &&
          activeDescendentIndex < suggestions.length - 1
        ) {
          dispatch({
            type: 'setActiveDescendentIndex',
            payload: activeDescendentIndex + 1,
          });
        } else {
          dispatch({ type: 'setActiveDescendentIndex', payload: 0 });
        }
        break;
      case KEYS.UP:
        e.preventDefault();

        dispatch({
          type: 'setActiveDescendentIndex',
          payload:
            activeDescendentIndex >= 1
              ? activeDescendentIndex - 1
              : suggestions.length - 1,
        });

        break;
      case KEYS.ENTER:
        e.preventDefault();
        if (activeDescendentIndex !== null) {
          selectItem({ selectedItem: suggestions[activeDescendentIndex] });
        }
        break;
      case KEYS.ESCAPE:
        e.preventDefault();
        // Clear the input and suggestions
        clearInput();
        break;
      case KEYS.COMMA:
      case KEYS.SPACE:
        e.preventDefault();
        // Accept whatever is in the input before the comma or space.
        // If any text remains after the comma or space, the edit will continue separately
        if (currentValue !== '') {
          selectByText({
            textValue: currentValue.slice(0, selectionStart),
            nextInputValue: currentValue.slice(selectionStart),
          });
        }
        break;
      case KEYS.DELETE:
        if (currentValue === '') {
          e.preventDefault();
          editPreviousSelectionIfExists();
        }
        break;
      default:
        if (!ALLOWED_CHARS_REGEX.test(e.key)) {
          e.preventDefault();
        }
    }
  };

  // If there is a previous selection, then pop it into edit mode
  const editPreviousSelectionIfExists = () => {
    if (selectedItems.length > 0 && inputPosition !== 0) {
      const nextEditIndex =
        inputPosition !== null ? inputPosition - 1 : selectedItems.length - 1;

      const item = selectedItems[nextEditIndex];
      deselectItem(item);
      enterEditState(item, nextEditIndex);
    }
  };

  const selectItem = ({
    selectedItem,
    nextInputValue = '',
    focusInput = true,
  }) => {
    // If a user has manually typed an item already selected, reset
    if (selectedItems.some((item) => item.name === selectedItem.name)) {
      clearInput();
      return;
    }

    // If an item was edited, we want to keep it in the same position in the list
    const insertIndex =
      inputPosition !== null ? inputPosition : selectedItems.length;
    const newSelections = [
      ...selectedItems.slice(0, insertIndex),
      selectedItem,
      ...selectedItems.slice(insertIndex),
    ];

    // We update the hidden selected items list, so additions are announced to screen reader users
    const listItem = document.createElement('li');
    listItem.innerText = selectedItem.name;
    selectedItemsRef.current.appendChild(listItem);

    exitEditState(nextInputValue);
    dispatch({ type: 'setSelectedItems', payload: newSelections });
    onSelectionsChanged(newSelections);

    // Clear the text input
    const { current: input } = inputRef;
    input.value = nextInputValue;
    if (focusInput) {
      dispatch({ type: 'setForceInputFocus', payload: true });
    }
  };

  const deselectItem = (deselectedItem) => {
    const newSelections = selectedItems.filter(
      (item) => item.name !== deselectedItem.name,
    );
    dispatch({
      type: 'setSelectedItems',
      payload: newSelections,
    });

    onSelectionsChanged(newSelections);

    // We also update the hidden selected items list, so removals are announced to screen reader users
    selectedItemsRef.current.querySelectorAll('li').forEach((selectionNode) => {
      if (selectionNode.innerText === deselectedItem.name) {
        selectionNode.remove();
      }
    });
  };

  const allSelectedItemElements = selectedItems.map((item, index) => {
    const { name: displayName } = item;
    return (
      <li key={displayName} className="w-max">
        <SelectionTemplate
          {...item}
          onEdit={() => enterEditState(item, index)}
          onDeselect={() => deselectItem(item)}
        />
      </li>
    );
  });

  // When a user edits a tag, we need to move the input inside the selected items
  const splitSelectionsAt =
    inputPosition !== null ? inputPosition : selectedItems.length;

  const allowSelections =
    !maxSelections || selectedItems.length < maxSelections;

  const input = allowSelections ? (
    <li className="self-center">
      <input
        ref={inputRef}
        autocomplete="off"
        className="c-autocomplete--multi__input"
        aria-activedescendant={
          activeDescendentIndex !== null
            ? suggestions[activeDescendentIndex]
            : null
        }
        aria-autocomplete="list"
        aria-labelledby="multi-select-label selected-items-list"
        type="text"
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        onBlur={handleInputBlur}
        placeholder={
          selectedItems.length > 0 ? PLACEHOLDER_SELECTIONS_MADE : placeholder
        }
      />
    </li>
  ) : null;

  return (
    <Fragment>
      <span
        ref={inputSizerRef}
        aria-hidden="true"
        className="absolute pointer-events-none opacity-0 p-2"
      />
      <label id="multi-select-label">{labelText}</label>

      {/* A visually hidden list provides confirmation messages to screen reader users as an item is selected or removed */}
      <div className="screen-reader-only">
        <p>Selected items:</p>
        <ul
          ref={selectedItemsRef}
          className="screen-reader-only list-none"
          aria-live="assertive"
          aria-atomic="false"
          aria-relevant="additions removals"
        />
      </div>

      <div className="c-autocomplete--multi relative">
        {/* disabled as the inner input forms the tab stop (this click handler ensures _any_ click on the wrapper focuses the input which may be less wide) */}
        {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events */}
        <div
          role={allowSelections ? 'combobox' : null}
          aria-haspopup={allowSelections ? 'listbox' : null}
          aria-expanded={allowSelections ? suggestions.length > 0 : null}
          aria-owns={allowSelections ? 'listbox1' : null}
          className={`c-autocomplete--multi__wrapper${
            border ? '-border' : ' border-none'
          } flex items-center crayons-textfield cursor-text `}
          onClick={() => inputRef.current?.focus()}
        >
          <ul id="combo-selected" className="list-none flex flex-wrap w-100">
            {allSelectedItemElements.slice(0, splitSelectionsAt)}
            {inputPosition !== null && input}
            {allSelectedItemElements.slice(splitSelectionsAt)}
            {inputPosition === null && input}
          </ul>
        </div>
        {suggestions.length > 0 ? (
          <ul
            className="c-autocomplete--multi__popover"
            aria-labelledby="multi-select-label"
            role="listbox"
            aria-multiselectable="true"
            id="listbox1"
          >
            {suggestions.map((suggestion, index) => {
              const { name: suggestionDisplayName } = suggestion;
              return (
                <li
                  id={suggestionDisplayName}
                  role="option"
                  aria-selected={index === activeDescendentIndex}
                  key={suggestionDisplayName}
                  onMouseDown={() => {
                    selectItem({ selectedItem: suggestion });
                    dispatch({ type: 'setIgnoreBlur', payload: true });
                  }}
                >
                  {SuggestionTemplate ? (
                    <SuggestionTemplate {...suggestion} />
                  ) : (
                    suggestionDisplayName
                  )}
                </li>
              );
            })}
          </ul>
        ) : null}
      </div>
    </Fragment>
  );
};
