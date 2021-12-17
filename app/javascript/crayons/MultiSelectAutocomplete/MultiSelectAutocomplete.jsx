/* eslint-disable jsx-a11y/interactive-supports-focus, jsx-a11y/role-has-required-aria-props */
// Disabled due to the linter being out of date for combobox role: https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/issues/789
import { h, Fragment } from 'preact';
import { useEffect, useRef, useReducer } from 'preact/hooks';
import { Icon, Button } from '@crayons';
import { Close } from '@images/x.svg';

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
      };
    case 'setActiveDescendentIndex':
      return { ...state, activeDescendentIndex: action.payload };
    case 'setIgnoreBlur':
      return { ...state, ignoreBlur: action.payload };
    default:
      return state;
  }
};

export const MultiSelectAutocomplete = ({ labelText, fetchSuggestions }) => {
  const [state, dispatch] = useReducer(reducer, {
    suggestions: [],
    selectedItems: [],
    inputPosition: null,
    editValue: '',
    activeDescendentIndex: null,
    ignoreBlur: false,
  });

  const {
    selectedItems,
    suggestions,
    inputPosition,
    editValue,
    activeDescendentIndex,
    ignoreBlur,
  } = state;

  const inputRef = useRef(null);
  const inputSizerRef = useRef(null);
  const selectedItemsRef = useRef(null);

  const handleInputBlur = () => {
    // Since the input is sometimes removed and rendered in a new location on blur, it's possible that inputRef.current may be null when we complete this check.
    const currentValue = inputRef.current ? inputRef.current.value : '';
    // The input will blur when user selects an option from the dropdown via mouse click. The ignoreBlur boolean lets us know we can ignore this event.
    if (!ignoreBlur && currentValue !== '') {
      selectItem({ selectedItem: currentValue, focusInput: false });
    } else {
      dispatch({ type: 'setSuggestions', payload: [] });
    }

    dispatch({ type: 'setIgnoreBlur', payload: false });
  };

  useEffect(() => {
    const { current: input } = inputRef;
    if (inputPosition !== null) {
      resizeInputToContentSize();

      input.value = editValue;
      const { length: cursorPosition } = editValue;
      input.focus();
      input.setSelectionRange(cursorPosition, cursorPosition);
    } else {
      // Remove inline style added to size the input
      input.style.width = '';
      input.focus();
    }
  }, [inputPosition, editValue]);

  const enterEditState = (editItem, editItemIndex) => {
    inputSizerRef.current.innerText = editItem;
    deselectItem(editItem);

    dispatch({
      type: 'updateEditState',
      payload: { editValue: editItem, inputPosition: editItemIndex },
    });
  };

  const exitEditState = (nextInputValue = '') => {
    inputSizerRef.current.innerText = nextInputValue;
    dispatch({
      type: 'updateEditState',
      payload: {
        editValue: nextInputValue,
        inputPosition: nextInputValue === '' ? null : inputPosition + 1,
      },
    });
  };

  const resizeInputToContentSize = () => {
    inputRef.current.style.width = `${inputSizerRef.current.clientWidth}px`;
  };

  const handleInputChange = async ({ target: { value } }) => {
    // When the input appears inline in "edit" mode, we need to dynamically calculate the width to ensure it occupies the right space
    // (an input cannot resize based on its text content). We use a hidden <span> to track the size.
    inputSizerRef.current.innerText = value;
    if (inputPosition !== null) {
      resizeInputToContentSize();
    }

    const results = await fetchSuggestions(value);
    dispatch({
      type: 'setSuggestions',
      payload: results.filter((item) => !selectedItems.includes(item)),
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
          selectItem({
            selectedItem: currentValue.slice(0, selectionStart),
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
    if (selectedItems.includes(selectedItem)) {
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
    listItem.innerText = selectedItem;
    selectedItemsRef.current.appendChild(listItem);

    exitEditState(nextInputValue);
    dispatch({ type: 'setSelectedItems', payload: newSelections });

    // Clear the text input
    const { current: input } = inputRef;
    input.value = nextInputValue;
    focusInput && input.focus();
  };

  const deselectItem = (deselectedItem) => {
    dispatch({
      type: 'setSelectedItems',
      payload: selectedItems.filter((item) => item !== deselectedItem),
    });

    // We also update the hidden selected items list, so removals are announced to screen reader users
    selectedItemsRef.current.querySelectorAll('li').forEach((selectionNode) => {
      if (selectionNode.innerText === deselectedItem) {
        selectionNode.remove();
      }
    });
  };

  const allSelectedItemElements = selectedItems.map((item, index) => (
    <li key={item} className="w-max">
      <div role="group" aria-label={item} className="flex mr-1 mb-1 w-max">
        <Button
          variant="secondary"
          className="c-autocomplete--multi__selected p-1 cursor-text"
          aria-label={`Edit ${item}`}
          onClick={() => enterEditState(item, index)}
        >
          {item}
        </Button>
        <Button
          variant="secondary"
          className="c-autocomplete--multi__selected p-1"
          aria-label={`Remove ${item}`}
          onClick={() => deselectItem(item)}
        >
          <Icon src={Close} />
        </Button>
      </div>
    </li>
  ));

  // When a user edits a tag, we need to move the input inside the selected items
  const splitSelectionsAt =
    inputPosition !== null ? inputPosition : selectedItems.length;

  const input = (
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
      />
    </li>
  );

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
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={suggestions.length > 0}
          aria-owns="listbox1"
          className="c-autocomplete--multi__wrapper flex items-center crayons-textfield cursor-text"
          onClick={() => inputRef.current.focus()}
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
            {suggestions.map((suggestion, index) => (
              // Focus remains in the input during keyboard use, and event handler is attached to that input
              // eslint-disable-next-line jsx-a11y/click-events-have-key-events
              <li
                id={suggestion}
                role="option"
                aria-selected={index === activeDescendentIndex}
                key={suggestion}
                onClick={() => selectItem({ selectedItem: suggestion })}
                onMouseDown={() =>
                  dispatch({ type: 'setIgnoreBlue', payload: true })
                }
              >
                {suggestion}
              </li>
            ))}
          </ul>
        ) : null}
      </div>
    </Fragment>
  );
};
