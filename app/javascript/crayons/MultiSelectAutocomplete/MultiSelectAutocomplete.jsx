/* eslint-disable jsx-a11y/interactive-supports-focus, jsx-a11y/role-has-required-aria-props */
// Disabled due to the linter being out of date for combobox role: https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/issues/789
import { h, Fragment } from 'preact';
import PropTypes from 'prop-types';
import { useEffect, useRef, useReducer } from 'preact/hooks';
import { DefaultSelectionTemplate } from '../../shared/components/defaultSelectionTemplate';

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
        selectedItems: action.payload.selectedItems,
        suggestions: action.payload.suggestions ?? state.suggestions,
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
    case 'setShowMaxSelectionsReached':
      return { ...state, showMaxSelectionsReached: action.payload };
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
 * @param {boolean} props.allowUserDefinedSelections Whether a user can create new selections other than the defined suggestions
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
  allowUserDefinedSelections = false,
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
    showMaxSelectionsReached: false,
  });

  const {
    selectedItems,
    suggestions,
    inputPosition,
    editValue,
    activeDescendentIndex,
    ignoreBlur,
    showMaxSelectionsReached,
  } = state;

  const inputRef = useRef(null);
  const inputSizerRef = useRef(null);
  const selectedItemsRef = useRef(null);
  const popoverRef = useRef(null);

  const allowSelections =
    !maxSelections || selectedItems.length < maxSelections;

  useEffect(() => {
    if (defaultValue.length > 0) {
      dispatch({
        type: 'setSelectedItems',
        payload: {
          selectedItems: defaultValue,
        },
      });
    }
  }, [defaultValue]);

  const handleInputBlur = () => {
    dispatch({ type: 'setShowMaxSelectionsReached', payload: false });

    const {
      current: { value: currentValue },
    } = inputRef;

    // The input will blur when user selects an option from the dropdown via mouse click. The ignoreBlur boolean lets us know we can ignore this event.
    if (!ignoreBlur && allowSelections && currentValue !== '') {
      selectByText({ textValue: currentValue, keepSelecting: false });
      return;
    }
    if (!ignoreBlur) {
      // Clear the suggestions if a genuine blur event
      dispatch({ type: 'setSuggestions', payload: [] });
    }
    exitEditState({ keepSelecting: false });
    dispatch({ type: 'setIgnoreBlur', payload: false });
  };

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
      input.setSelectionRange(cursorPosition, cursorPosition);

      // Trigger the input event to make sure suggestion UI updates correctly
      const changeEvent = new Event('input');
      input.dispatchEvent(changeEvent);
    }
  }, [inputPosition, editValue]);

  useEffect(() => {
    if (activeDescendentIndex !== null) {
      const { current: popover } = popoverRef;
      const activeItem = popover?.querySelector('[aria-selected="true"]');
      if (!popover || !activeItem) {
        return;
      }

      // Make sure that the active item is scrolled into view, if need be
      const { offsetHeight, offsetTop } = activeItem;
      const { offsetHeight: popoverOffsetHeight, scrollTop } = popover;

      const isAbove = offsetTop < scrollTop;
      const isBelow =
        offsetTop + offsetHeight > scrollTop + popoverOffsetHeight;

      if (isAbove) {
        popover.scrollTo(0, offsetTop);
      } else if (isBelow) {
        popover.scrollTo(0, offsetTop - popoverOffsetHeight + offsetHeight);
      }
    }
  }, [activeDescendentIndex]);

  const selectByText = ({
    textValue,
    nextInputValue = '',
    keepSelecting = true,
  }) => {
    const matchingSuggestion = suggestions.find(
      (suggestion) => suggestion.name === textValue,
    );

    if (matchingSuggestion) {
      selectItem({
        selectedItem: matchingSuggestion,
        nextInputValue,
        keepSelecting,
      });
      return;
    }

    // If we allow user's own input as a selection, fallback to that
    if (allowUserDefinedSelections) {
      selectItem({
        selectedItem: { name: textValue },
        nextInputValue,
        keepSelecting,
      });
      return;
    }

    // If we couldn't select any valid input, and search is terminated, clear the input
    if (!keepSelecting) {
      inputRef.current.value = '';
      dispatch('setSuggestions', { payload: [] });
    }
  };

  const enterEditState = (editItem, editItemIndex) => {
    inputSizerRef.current.innerText = editItem.name;
    deselectItem(editItem);

    dispatch({
      type: 'updateEditState',
      payload: {
        editValue: editItem.name,
        inputPosition: editItemIndex,
      },
    });
  };

  const exitEditState = ({ nextInputValue = '', keepSelecting = true }) => {
    // Reset 'edit mode' input resizing
    inputRef.current?.style?.removeProperty('width');
    inputSizerRef.current.innerText = nextInputValue;

    dispatch({
      type: 'updateEditState',
      payload: {
        editValue: nextInputValue,
        inputPosition: nextInputValue === '' ? null : inputPosition + 1,
      },
    });

    // Blurring away while clearing the input
    if (!keepSelecting && nextInputValue === '') {
      inputRef.current.value = '';
    }
  };

  const resizeInputToContentSize = () => {
    const { current: input } = inputRef;

    if (input) {
      input.style.width = `${inputSizerRef.current.clientWidth}px`;
    }
  };

  const handleAutocompleteStart = () => {
    // Only show static suggestions when not in edit mode
    if (inputPosition !== null) {
      return;
    }

    // If we've already reached max selections, show the message rather than static suggestions
    if (!allowSelections) {
      dispatch({ type: 'setShowMaxSelectionsReached', payload: true });
      return;
    }

    // If we have static suggestions, and no search term, show the static suggestions
    if (staticSuggestions.length > 0 && inputRef.current?.value === '') {
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
  };

  const handleInputChange = async ({ target: { value } }) => {
    // When the input appears inline in "edit" mode, we need to dynamically calculate the width to ensure it occupies the right space
    // (an input cannot resize based on its text content). We use a hidden <span> to track the size.
    inputSizerRef.current.innerText = value;

    if (inputPosition !== null) {
      resizeInputToContentSize();
    }

    // If max selections have already been reached, no need to fetch further suggestions
    if (!allowSelections) {
      return;
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

    // It could be that while waiting on the network fetch, the user has already made a selection or otherwise cleared the input
    if (inputRef.current.value === '') {
      return;
    }

    // If no results, and user-generated selections are allowed, display current search term as an option
    if (allowUserDefinedSelections && results.length === 0 && value !== '') {
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
        if (currentValue !== '' && allowSelections) {
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

  const getEmptyInputSuggestions = ({ currentSelections = selectedItems }) => {
    if (staticSuggestions.length > 0) {
      return staticSuggestions.filter(
        (suggestion) =>
          !currentSelections.some(
            (selection) => selection.name === suggestion.name,
          ),
      );
    }

    return [];
  };

  const selectItem = ({
    selectedItem,
    nextInputValue = '',
    keepSelecting = true,
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

    exitEditState({ nextInputValue, keepSelecting });

    dispatch({
      type: 'setSelectedItems',
      payload: {
        selectedItems: newSelections,
        suggestions: keepSelecting
          ? getEmptyInputSuggestions({
              currentSelections: newSelections,
            })
          : [],
      },
    });

    onSelectionsChanged?.(newSelections);

    // Clear the text input
    const { current: input } = inputRef;
    input.value = nextInputValue;

    if (keepSelecting) {
      dispatch({
        type: 'setShowMaxSelectionsReached',
        payload: maxSelections && newSelections.length >= maxSelections,
      });

      // setTimeout is used with no delay here to make sure this focus event is executed in the next event cycle.
      // selectItem() happens on mousedown rather than click, because mousedown is handled before the blur event, and we
      // want to ignore some blur events (i.e. when input blurs because user has clicked a dropdown option).
      // By using setTimeout, we make sure that the normal blur event is handled before we try to refocus the input.
      setTimeout(() => {
        input.focus();
      });
    }
  };

  const deselectItem = (deselectedItem) => {
    const newSelections = selectedItems.filter(
      (item) => item.name !== deselectedItem.name,
    );
    dispatch({
      type: 'setSelectedItems',
      payload: {
        selectedItems: newSelections,
        suggestions,
      },
    });

    dispatch({
      type: 'setShowMaxSelectionsReached',
      payload: maxSelections && newSelections.length >= maxSelections,
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
          buttonVariant="secondary"
          onEdit={() => enterEditState(item, index)}
          onDeselect={() => deselectItem(item)}
        />
      </li>
    );
  });

  const selectionsPlaceholder =
    selectedItems.length > 0 ? PLACEHOLDER_SELECTIONS_MADE : placeholder;

  const inputPlaceholder = allowSelections ? selectionsPlaceholder : null;

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
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded={suggestions.length > 0}
          aria-owns="listbox1"
          className={`c-autocomplete--multi__wrapper${
            border ? '-border crayons-textfield' : ' border-none p-0'
          } flex items-center  cursor-text`}
          onClick={(event) => {
            // Stopping propagation here so that clicks on the 'x' close button
            // don't appear to be "outside" of any container (eg, dropdown)
            event.stopPropagation();
            inputRef.current?.focus();
          }}
        >
          <ul id="combo-selected" className="list-none flex flex-wrap w-100">
            {allSelectedItemElements}

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
                aria-disabled={!allowSelections}
                type="text"
                onChange={handleInputChange}
                onKeyDown={handleKeyDown}
                onBlur={handleInputBlur}
                onFocus={(e) => {
                  onFocus?.(e);
                  handleAutocompleteStart();
                }}
                placeholder={inputPosition === null ? inputPlaceholder : null}
              />
            </li>
          </ul>
        </div>
        {showMaxSelectionsReached ? (
          <div className="c-autocomplete--multi__popover">
            <span className="p-3">Only {maxSelections} selections allowed</span>
          </div>
        ) : null}
        {suggestions.length > 0 && allowSelections ? (
          <div className="c-autocomplete--multi__popover" ref={popoverRef}>
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
