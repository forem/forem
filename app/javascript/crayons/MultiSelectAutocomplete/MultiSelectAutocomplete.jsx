/* eslint-disable jsx-a11y/interactive-supports-focus, jsx-a11y/role-has-required-aria-props */
// Disabled due to the linter being out of date for combobox role: https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/issues/789
import { h, Fragment } from 'preact';
import { useState, useEffect, useRef } from 'preact/hooks';
import { Icon } from '@crayons';
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

export const MultiSelectAutocomplete = ({ labelText, fetchSuggestions }) => {
  const [suggestions, setSuggestions] = useState([]);
  const [selectedItems, setSelectedItems] = useState([]);
  const [inputPosition, setInputPosition] = useState(null);
  const [editValue, setEditValue] = useState('');
  const [activeDescendentIndex, setActiveDescendentIndex] = useState(null);
  const [ignoreBlur, setIgnoreBlur] = useState(false);

  const inputRef = useRef(null);
  const inputSizerRef = useRef(null);
  const selectedItemsRef = useRef(null);

  const handleInputBlur = () => {
    // Since the input is sometimes removed and rendered in a new location on blur, it's possible that inputRef.current may be null when we complete this check.
    const currentValue = inputRef.current ? inputRef.current.value : '';
    // The input will blur when user selects an option from the dropdown via mouse click. The ignoreBlur boolean lets us know we can ignore this event.
    if (!ignoreBlur && currentValue !== '') {
      selectItem({ selectedItem: currentValue, focusInput: false });
    }
    setIgnoreBlur(false);
  };

  useEffect(() => {
    if (inputPosition !== null) {
      resizeInputToContentSize();

      const { current: input } = inputRef;
      input.value = editValue;
      const { length: cursorPosition } = editValue;
      input.focus();
      input.setSelectionRange(cursorPosition, cursorPosition);
    } else {
      // Remove inline style added to size the input
      inputRef.current.style.width = '';
      inputRef.current.focus();
    }
  }, [inputPosition, editValue]);

  const enterEditState = (editItem, editItemIndex) => {
    inputSizerRef.current.innerText = editItem;
    setEditValue(editItem);
    setInputPosition(editItemIndex);
  };

  const exitEditState = (nextInputValue = '') => {
    inputSizerRef.current.innerText = nextInputValue;
    setEditValue(nextInputValue);
    setInputPosition(nextInputValue === '' ? null : inputPosition + 1);
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
    setSuggestions(results.filter((item) => !selectedItems.includes(item)));
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
          setActiveDescendentIndex(activeDescendentIndex + 1);
        } else {
          setActiveDescendentIndex(0);
        }
        break;
      case KEYS.UP:
        e.preventDefault();

        if (activeDescendentIndex >= 1) {
          setActiveDescendentIndex(activeDescendentIndex - 1);
        } else {
          setActiveDescendentIndex(suggestions.length - 1);
        }
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
        inputRef.current.value = '';
        setSuggestions([]);
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
    // If an item was edited, we want to keep it in the same position in the list
    const insertIndex = inputPosition ? inputPosition : selectedItems.length;
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
    setSelectedItems(newSelections);
    // Clear the currently displayed suggestions & active index
    setSuggestions([]);
    setActiveDescendentIndex(null);
    // Clear the text input
    const { current: input } = inputRef;
    input.value = nextInputValue;
    focusInput && input.focus();
  };

  const deselectItem = (deselectedItem) => {
    setSelectedItems(selectedItems.filter((item) => item !== deselectedItem));

    // We also update the hidden selected items list, so removals are announced to screen reader users
    selectedItemsRef.current.querySelectorAll('li').forEach((selectionNode) => {
      if (selectionNode.innerText === deselectedItem) {
        selectionNode.remove();
      }
    });
  };

  const allSelectedItemElements = selectedItems.map((item, index) => (
    <li key={item} className="w-max">
      <button className="mr-1 mb-1 w-max" onClick={() => deselectItem(item)}>
        {/* The span intentionally does not have a keyboard click event */}
        {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions */}
        <span onClick={() => enterEditState(item, index)}>{item}</span>
        <span className="screen-reader-only"> (remove)</span>
        <Icon src={Close} />
      </button>
    </li>
  ));

  // TODO:

  // Should the text and the remove button be separate buttons within a shared group? This would make the feature accessible, but maybe confusing

  // When a user edits a tag, we need to move the input inside the selected items
  const splitSelectionsAt =
    inputPosition !== null ? inputPosition : selectedItems.length;

  const input = (
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
      id="multi-select-combobox"
      type="text"
      onChange={handleInputChange}
      onKeyDown={handleKeyDown}
      onBlur={handleInputBlur}
    />
  );

  return (
    <Fragment>
      <span
        ref={inputSizerRef}
        aria-hidden="true"
        className="absolute pointer-events-none opacity-0 p-2"
      />
      <label id="multi-select-label">{labelText}</label>

      <ul
        id="selected-items-list"
        ref={selectedItemsRef}
        className="screen-reader-only"
        aria-live="assertive"
        aria-atomic="false"
        aria-relevant="additions removals"
      />

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
                onMouseDown={() => setIgnoreBlur(true)}
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
