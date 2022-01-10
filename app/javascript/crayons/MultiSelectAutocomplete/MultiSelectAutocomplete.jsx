/* eslint-disable jsx-a11y/interactive-supports-focus, jsx-a11y/role-has-required-aria-props */
// Disabled due to the linter being out of date for combobox role: https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/issues/789
import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
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

/**
 * Component allowing users to search and select multiple values
 *
 * @param {Object} props
 * @param {string} props.labelText The text for the input's label
 * @param {boolean} props.showLabel Whether the label text should be visible or hidden (for assistive tech users only)
 * @param {Function} props.fetchSuggestions Callback function which accepts the search term string and returns an array of suggestions
 * @param {Array} props.defaultValue Array of items which should be selected by default
 * @param {Array} props.staticSuggestions Array of items which should be suggested if no search term has been entered yet
 * @param {string} props.staticSuggestionsHeading Optional heading to display when static suggestions are rendered
 * @param {boolean} props.border Whether to show a bordered input
 * @param {string} props.placeholder Input placeholder text
 * @param {string} props.inputId ID to be applied to the input element
 * @param {number} props.maxSelections Optional maximum number of allowed selections
 * @param {Function} props.onSelectionsChanged Callback for when selections are added or removed
 * @param {Function} props.onFocus Callback for when the component receives focus
 * @param {Function} props.SuggestionTemplate Optional Preact component to render suggestion items
 * @param {Function} props.SelectionTemplate Optional Preact component to render selected items
 */
export const MultiSelectAutocomplete = ({
  labelText,
  showLabel = true,
  fetchSuggestions,
  defaultValue = [],
  staticSuggestions = [],
  staticSuggestionsHeading,
  border = true,
  placeholder = 'Add...',
  inputId,
  maxSelections,
  onSelectionsChanged,
  onFocus,
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
    // If user has reached their max selections, the inputRef may not be defined
    const currentValue = inputRef.current ? inputRef.current.value : '';

    // The input will blur when user selects an option from the dropdown via mouse click. The ignoreBlur boolean lets us know we can ignore this event.
    if (!ignoreBlur && currentValue !== '') {
      selectByText({ textValue: currentValue, focusInput: false });
    } else {
      exitEditState({ focusInput: false });
      dispatch({ type: 'setSuggestions', payload: [] });
      dispatch({ type: 'setIgnoreBlur', payload: false });
    }
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

      // Trigger the input event to make sure suggestion UI updates correctly
      const changeEvent = new Event('input');
      input.dispatchEvent(changeEvent);
    }
  }, [inputPosition, editValue]);

  useEffect(() => {
    if (forceInputFocus) {
      // If the user has reached their max selections, it's possible the input will not be available to focus.
      // In this case, the last 'deselect' button in the widget is focused as a fallback.
      const isInputAvailable = inputRef.current;

      if (isInputAvailable) {
        inputRef.current?.focus();
      } else {
        const selectionButtons = document
          .getElementById('combo-selected')
          .querySelectorAll('button');
        selectionButtons[selectionButtons.length - 1].focus();
      }

      dispatch({ type: 'setForceInputFocus', payload: false });
    }
  }, [forceInputFocus, maxSelections, selectedItems.length]);

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

  const exitEditState = ({ nextInputValue = '', focusInput = true }) => {
    // Reset 'edit mode' input resizing
    inputRef.current?.style?.removeProperty('width');
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
        forceInputFocus: focusInput,
      },
    });
  };

  const resizeInputToContentSize = () => {
    const { current: input } = inputRef;

    if (input) {
      input.style.width = `${inputSizerRef.current.clientWidth}px`;
    }
  };

  const handleInputFocus = (e) => {
    // Only show static suggestions when not in edit mode
    if (inputPosition !== null) {
      return;
    }

    const shouldShowStaticSuggestions =
      staticSuggestions.length > 0 && inputRef.current?.value === '';
    if (shouldShowStaticSuggestions) {
      dispatch({
        type: 'setSuggestions',
        payload: staticSuggestions.filter(
          (item) =>
            !selectedItems.some(
              (selectedItem) => selectedItem.name === item.name,
            ),
        ),
      });
    }
    onFocus?.(e);
  };

  const handleInputChange = async ({ target: { value } }) => {
    // When the input appears inline in "edit" mode, we need to dynamically calculate the width to ensure it occupies the right space
    // (an input cannot resize based on its text content). We use a hidden <span> to track the size.

    inputSizerRef.current.innerText = value;

    if (inputPosition !== null) {
      resizeInputToContentSize();
    }

    if (value === '') {
      dispatch({
        type: 'setSuggestions',
        payload: staticSuggestions.filter(
          (item) =>
            !selectedItems.some(
              (selectedItem) => selectedItem.name === item.name,
            ),
        ),
      });
      return;
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

    exitEditState({ nextInputValue, focusInput });
    dispatch({ type: 'setSelectedItems', payload: newSelections });
    onSelectionsChanged?.(newSelections);

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

    onSelectionsChanged?.(newSelections);

    // We also update the hidden selected items list, so removals are announced to screen reader users
    selectedItemsRef.current.querySelectorAll('li').forEach((selectionNode) => {
      if (selectionNode.innerText === deselectedItem.name) {
        selectionNode.remove();
      }
    });
  };

  const allSelectedItemElements = selectedItems.map((item, index) => {
    // When we are in "edit mode" we visually display the input between the other selections
    const defaultPosition = index + 1;
    const appearsBeforeInput = inputPosition === null || index < inputPosition;
    const position = appearsBeforeInput ? defaultPosition : defaultPosition + 1;

    const { name: displayName } = item;
    return (
      <li
        key={displayName}
        className="c-autocomplete--multi__selection-list-item w-max"
        style={{ order: position }}
      >
        <SelectionTemplate
          {...item}
          onEdit={() => enterEditState(item, index)}
          onDeselect={() => deselectItem(item)}
        />
      </li>
    );
  });

  const allowSelections =
    !maxSelections || selectedItems.length < maxSelections;

  const inputPlaceholder =
    selectedItems.length > 0 ? PLACEHOLDER_SELECTIONS_MADE : placeholder;

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
      <span id="input-description" className="screen-reader-only">
        {maxSelections ? `Maximum ${maxSelections} selections` : ''}
      </span>

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
            border ? '-border' : ' border-none p-0'
          } flex items-center crayons-textfield cursor-text`}
          onClick={() => inputRef.current?.focus()}
        >
          <ul id="combo-selected" className="list-none flex flex-wrap w-100">
            {allSelectedItemElements}
            {allowSelections ? (
              <li
                className="self-center"
                style={{
                  order:
                    inputPosition === null
                      ? selectedItems.length + 1
                      : inputPosition + 1,
                }}
              >
                <input
                  id={inputId}
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
                  aria-describedby="input-description"
                  type="text"
                  onChange={handleInputChange}
                  onKeyDown={handleKeyDown}
                  onBlur={handleInputBlur}
                  onFocus={handleInputFocus}
                  placeholder={inputPosition === null ? inputPlaceholder : null}
                />
              </li>
            ) : null}
          </ul>
        </div>
        {suggestions.length > 0 ? (
          <div className="c-autocomplete--multi__popover">
            {inputRef.current?.value === '' ? staticSuggestionsHeading : null}
            <ul
              className="list-none"
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
          </div>
        ) : null}
      </div>
    </Fragment>
  );
};

const optionPropType = PropTypes.shape({ name: PropTypes.string });

MultiSelectAutocomplete.propTypes = {
  labelText: PropTypes.string.isRequired,
  showLabel: PropTypes.bool,
  fetchSuggestions: PropTypes.func.isRequired,
  defaultValue: PropTypes.arrayOf(optionPropType),
  staticSuggestions: PropTypes.arrayOf(optionPropType),
  staticSuggestionsHeading: PropTypes.oneOfType([
    PropTypes.element,
    PropTypes.string,
  ]),
  border: PropTypes.bool,
  placeholder: PropTypes.string,
  inputId: PropTypes.string,
  maxSelections: PropTypes.number,
  onSelectionsChanged: PropTypes.func,
  onFocus: PropTypes.func,
  SuggestionTemplate: PropTypes.func,
  SelectionTemplate: PropTypes.func,
};
