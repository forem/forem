import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import { useRef, useState, useEffect } from 'preact/hooks';
import { DefaultSelectionTemplate } from '../../shared/components/defaultSelectionTemplate';

const KEYS = {
  ENTER: 'Enter',
  COMMA: ',',
  SPACE: ' ',
  DELETE: 'Backspace',
};

/**
 * Component allowing users to add multiple entries for a given input field that get displayed as destructive pills
 *
 * @param {Object} props
 * @param {string} props.labelText The text for the input's label
 * @param {boolean} props.showLabel Whether the label text should be visible or hidden (for assistive tech users only)
 * @param {string} props.placeholder Input placeholder text
 * @param {string} props.inputRegex Optional regular expression used to restrict the input
 * @param {string} props.validationRegex Optional regular expression used to validate the value of the input
 * @param {Function} props.SelectionTemplate Optional Preact component to render selected items
 */

export const MultiInput = ({
  placeholder,
  inputRegex,
  validationRegex,
  showLabel = true,
  labelText,
  SelectionTemplate = DefaultSelectionTemplate,
}) => {
  const inputRef = useRef(null);
  const inputSizerRef = useRef(null);
  const selectedItemsRef = useRef(null);

  const [items, setItems] = useState([]);
  const [editValue, setEditValue] = useState(null);
  const [inputPosition, setInputPosition] = useState(null);

  useEffect(() => {
    // editValue defaults to null when component is first rendered.
    // This ensures we do not autofocus the input before the user has started interacting with the component.
    if (editValue === null) {
      return;
    }

    const { current: input } = inputRef;
    if (input && inputPosition !== null) {
      // Entering 'edit' mode
      resizeInputToContentSize();
      input.value = editValue;
      const { length: cursorPosition } = editValue;
      input.focus();
      // This will set the cursor position at the end of the text.
      input.setSelectionRange(cursorPosition, cursorPosition);
    }
  }, [inputPosition, editValue]);

  const handleInputBlur = ({ target: { value } }) => {
    addItemToList(value);
    clearInput();
  };

  const handleInputChange = async ({ target: { value } }) => {
    // When the input appears inline in "edit" mode, we need to dynamically calculate the width to ensure it occupies the right space
    // (an input cannot resize based on its text content). We use a hidden <span> to track the size.
    inputSizerRef.current.innerText = value;

    if (inputPosition !== null) {
      resizeInputToContentSize();
    }
  };

  const handleKeyDown = (e) => {
    const { value: currentValue } = inputRef.current;

    switch (e.key) {
      case KEYS.SPACE:
      case KEYS.ENTER:
      case KEYS.COMMA:
        e.preventDefault();
        addItemToList(e.target.value);
        clearInput();
        break;
      case KEYS.DELETE:
        if (currentValue === '') {
          e.preventDefault();
          editPreviousSelectionIfExists();
        }
        break;
      default:
        if (inputRegex && !inputRegex.test(e.key)) {
          e.preventDefault();
        }
    }
  };

  const addItemToList = (value) => {
    if (value.trim().length > 0) {
      // If an item was edited, we want to keep it in the same position in the list
      const insertIndex = inputPosition !== null ? inputPosition : items.length;

      // if we do not pass in a validationRegex we can assume that anything is valid
      const valid = validationRegex ? checkValidity(value) : true;
      const newSelections = [
        ...items.slice(0, insertIndex),
        { value, valid },
        ...items.slice(insertIndex),
      ];

      // We update the hidden selected items list, so additions are announced to screen reader users
      const listItem = document.createElement('li');
      listItem.innerText = value;
      selectedItemsRef.current.appendChild(listItem);

      setItems([...newSelections]);
      exitEditState({});
    }
  };

  const checkValidity = (value) => {
    return validationRegex.test(value);
  };

  const clearInput = () => {
    inputRef.current.value = '';
  };

  const resizeInputToContentSize = () => {
    const { current: input } = inputRef;

    if (input) {
      input.style.width = `${inputSizerRef.current.clientWidth}px`;
    }
  };

  const deselectItem = (clickedItem) => {
    const newArr = items.filter((item) => item.value !== clickedItem);
    setItems(newArr);

    // We also update the hidden selected items list, so removals are announced to screen reader users
    selectedItemsRef.current.querySelectorAll('li').forEach((selectionNode) => {
      if (selectionNode.innerText === clickedItem) {
        selectionNode.remove();
      }
    });
  };

  // If there is a previous selection, then pop it into edit mode
  const editPreviousSelectionIfExists = () => {
    if (items.length > 0 && inputPosition !== 0) {
      const nextEditIndex =
        inputPosition !== null ? inputPosition - 1 : items.length - 1;

      const item = items[nextEditIndex];
      enterEditState(item.value, nextEditIndex);
    }
  };

  const enterEditState = (editItem, editItemIndex) => {
    inputSizerRef.current.innerText = editItem;
    deselectItem(editItem);
    setEditValue(editItem);
    setInputPosition(editItemIndex);
  };

  const exitEditState = ({ nextInputValue = '' }) => {
    // Reset 'edit mode' input resizing
    inputRef.current?.style?.removeProperty('width');

    inputSizerRef.current.innerText = nextInputValue;
    setEditValue(nextInputValue);
    setInputPosition(nextInputValue === '' ? null : inputPosition + 1);
    // Blurring away while clearing the input
    if (nextInputValue === '') {
      inputRef.current.value = '';
    }
  };

  const allSelectedItemElements = items.map((item, index) => {
    // When we are in "edit mode" we visually display the input between the other selections
    // If the item being edited appears before the item being rendered then we set its position to
    // the index + 1 which matches the order, however, any items that appear after the item that is
    // being edited will need to increment their position by one to make place for the item being edited.

    // at this point the position is already set
    const defaultPosition = index + 1;
    const appearsBeforeInput = inputPosition === null || index < inputPosition;
    const position = appearsBeforeInput ? defaultPosition : defaultPosition + 1;
    return (
      <li
        key={index}
        className="c-input--multi__selection-list-item w-max"
        style={{ order: position }}
      >
        <SelectionTemplate
          name={item.value}
          className={`c-input--multi__selected ${
            !item.valid ? 'c-input--multi__selected-invalid' : ''
          }`}
          enableValidation={true}
          valid={item.valid}
          onEdit={() => enterEditState(item.value, index)}
          onDeselect={() => deselectItem(item.value)}
        />
      </li>
    );
  });

  return (
    <Fragment>
      <span
        ref={inputSizerRef}
        aria-hidden="true"
        className="absolute pointer-events-none opacity-0 p-2"
      />
      <label
        id="multi-select-label"
        className={showLabel ? '' : 'screen-reader-only'}
      >
        {labelText}
      </label>

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

      <div class="c-input--multi relative">
        <div class="c-input--multi__wrapper-border crayons-textfield flex items-center cursor-text pb-9">
          <ul class="list-none flex flex-wrap w-100">
            {allSelectedItemElements}
            <li
              class="self-center"
              style={{
                order:
                  inputPosition === null ? items.length + 1 : inputPosition + 1,
              }}
            >
              <input
                autocomplete="off"
                class="c-input--multi__input"
                type="text"
                aria-labelledby="multi-select-label"
                onBlur={handleInputBlur}
                onKeyDown={handleKeyDown}
                placeholder={inputPosition === null ? placeholder : null}
                onChange={handleInputChange}
                ref={inputRef}
              />
            </li>
          </ul>
        </div>
      </div>
    </Fragment>
  );
};

MultiInput.propTypes = {
  labelText: PropTypes.string.isRequired,
  showLabel: PropTypes.bool,
  placeholder: PropTypes.string,
  inputRegex: PropTypes.string,
  validationRegex: PropTypes.string,
  SelectionTemplate: PropTypes.func,
};
