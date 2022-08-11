import { h } from 'preact';
import { useRef, useLayoutEffect, useReducer, useEffect } from 'preact/hooks';
import { forwardRef, createPortal } from 'preact/compat';
import { UserListItemContent } from './UserListItemContent';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';
import { isInViewport } from '@utilities/viewport';

import {
  useTextAreaAutoResize,
  getAutocompleteWordData,
  getCursorXY,
} from '@utilities/textAreaUtils';

// Used to ensure dropdown appears just below search text
const DROPDOWN_VERTICAL_OFFSET = '1.5rem';
const EMPTY_STATE_MESSAGE = 'No results found';
const MINIMUM_SEARCH_CHARS = 2;

const KEYS = {
  UP: 'ArrowUp',
  DOWN: 'ArrowDown',
  ENTER: 'Enter',
  ESCAPE: 'Escape',
};

/**
 * Helper function to copy all styles and attributes from the original textarea to the new autocomplete one
 *
 * @param {object} options
 * @param {element} options.originalTextArea The textarea DOM element that should be replaced/removed
 * @param {element} options.newTextArea The textarea DOM element containing the autocomplete functionality. It will receive all attributes and styles of the original node.
 */
const replaceTextArea = ({ originalTextArea, newTextArea }) => {
  const { attributes } = originalTextArea;
  const { cssText } = document.defaultView.getComputedStyle(
    originalTextArea,
    '',
  );

  // Make sure all attributes are copied over
  Object.keys(attributes).forEach((attributeKey) => {
    newTextArea.setAttribute(
      attributes[attributeKey].name,
      attributes[attributeKey].value,
    );
  });

  // Make sure all styles are copied over
  newTextArea.style.cssText = cssText;
  // Make sure no transition replays when the new textarea is mounted
  newTextArea.style.transition = 'none';
  // Copy any initial value
  newTextArea.value = originalTextArea.value;

  // We need to manually remove the original element, as Preact's diffing algorithm won't replace it in render
  originalTextArea.remove();
};

/**
 * Helper function to merge any additional ref passed to the textArea with the ref used internally by this component.
 *
 * @param {Array} refs Array of all references
 */
const mergeInputRefs = (refs) => (value) => {
  refs.forEach((ref) => {
    if (ref) {
      ref.current = value;
    }
  });
};

const reducer = (state, action) => {
  switch (action.type) {
    case 'setIsComboboxMode':
      return { ...state, isComboboxMode: action.payload };
    case 'setSuggestions':
      return { ...state, suggestions: action.payload };
    case 'setDropdownPositionPoints':
      return { ...state, dropdownPositionPoints: action.payload };
    case 'setActiveDescendentIndex':
      return { ...state, activeDescendentIndex: action.payload };
    case 'setSuppressPopover':
      return { ...state, suppressPopover: action.payload };
    case 'setEmptyStateMessage':
      return { ...state, emptyStateMessage: action.payload };
    case 'setIgnoreBlur':
      return { ...state, ignoreBlur: action.payload };
    case 'exitComboboxMode':
      return {
        ...state,
        suggestions: [],
        activeDescendentIndex: null,
        isComboboxMode: false,
      };

    default:
      return state;
  }
};

/**
 * Renders a textarea with enhanced autocomplete functionality.
 * Autocomplete searching will start when user types the given trigger character, with suggestions fetched via fetchSuggestions callback.
 * Can optionally replace an existing textarea, passed as the replaceElement prop.
 */
export const AutocompleteTriggerTextArea = forwardRef(
  (
    {
      id,
      triggerCharacter,
      autoResize = false,
      onChange,
      onBlur,
      fetchSuggestions,
      searchInstructionsMessage,
      maxSuggestions,
      replaceElement,
      ...inputProps
    },
    forwardedRef,
  ) => {
    const [state, dispatch] = useReducer(reducer, {
      isComboboxMode: false,
      suggestions: [],
      dropdownPositionPoints: {
        x: 0,
        y: 0,
      },
      activeDescendentIndex: null,
      suppressPopover: false,
      emptyStateMessage: searchInstructionsMessage,
      ignoreBlur: false,
    });

    const {
      isComboboxMode,
      suggestions,
      dropdownPositionPoints,
      activeDescendentIndex,
      suppressPopover,
      emptyStateMessage,
      ignoreBlur,
    } = state;

    const isSmallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Small}px)`);

    const inputRef = useRef(null);
    const popoverRef = useRef(null);
    const wrapperRef = useRef(null);

    const { setTextArea, setAdditionalElements } = useTextAreaAutoResize();

    useEffect(() => {
      if (activeDescendentIndex !== null) {
        const { current: popover } = popoverRef;
        const activeItem = popover?.querySelector('[aria-selected="true"]');
        if (!popover || !activeItem) {
          return;
        }

        if (!isInViewport({ element: activeItem })) {
          activeItem.scrollIntoView(false);
        }
      }
    }, [activeDescendentIndex]);

    useLayoutEffect(() => {
      if (autoResize && inputRef.current) {
        setTextArea(inputRef.current);
        setAdditionalElements([wrapperRef.current]);
      }
    }, [autoResize, setTextArea, setAdditionalElements]);

    useLayoutEffect(() => {
      const { current: enhancedTextArea } = inputRef;

      if (enhancedTextArea && replaceElement) {
        replaceTextArea({
          originalTextArea: replaceElement,
          newTextArea: enhancedTextArea,
        });
        enhancedTextArea.focus({ preventScroll: true });
      }
    }, [replaceElement]);

    const handleInputChange = () => {
      const { current: currentInput } = inputRef;

      const {
        isTriggered: isSearching,
        indexOfAutocompleteStart: indexOfSearchStart,
      } = getAutocompleteWordData({
        textArea: currentInput,
        triggerCharacter,
      });

      dispatch({ type: 'setIsComboboxMode', payload: isSearching });

      if (!isSearching) {
        dispatch({ type: 'setSuggestions', payload: [] });
        return;
      }

      // Fetch suggestions
      const { selectionStart, value: currentValue } = currentInput;

      // Search term begins after the triggerCharacter
      const searchTermStartPosition = indexOfSearchStart + 1;

      const searchTerm = currentValue.substring(
        searchTermStartPosition,
        selectionStart,
      );

      if (searchTerm.length >= MINIMUM_SEARCH_CHARS) {
        fetchSuggestions(searchTerm).then((suggestions) => {
          if (maxSuggestions && suggestions.length > maxSuggestions) {
            dispatch({
              type: 'setSuggestions',
              payload: suggestions.slice(0, maxSuggestions),
            });
            return;
          }
          dispatch({ type: 'setSuggestions', payload: suggestions });
        });

        dispatch({
          type: 'setEmptyStateMessage',
          payload: EMPTY_STATE_MESSAGE,
        });
      } else {
        dispatch({
          type: 'setEmptyStateMessage',
          payload: searchInstructionsMessage,
        });
      }

      // Ensure dropdown is properly positioned
      const { x: cursorX, y } = getCursorXY({
        input: currentInput,
        selectionPoint: indexOfSearchStart,
      });
      const textAreaX = currentInput.offsetLeft;

      // On small screens always show dropdown at start of textarea
      const dropdownX = isSmallScreen ? textAreaX : cursorX;

      dispatch({
        type: 'setDropdownPositionPoints',
        payload: { x: dropdownX, y },
      });
    };

    const handleKeyDown = (e) => {
      // If we are not in combobox mode, ignore
      if (!isComboboxMode) {
        return;
      }

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
            selectSuggestion(suggestions[activeDescendentIndex]);
          }
          break;
        case KEYS.ESCAPE:
          e.preventDefault();
          // Temporarily close the popover until next keypress
          dispatch({ type: 'setSuppressPopover', payload: true });

          return;
      }
      dispatch({ type: 'setSuppressPopover', payload: false });
    };

    // If a user clicks away from an in-progress search, we can assume they no longer wish to keep searching
    const handleTextAreaClicked = () => dispatch({ type: 'exitComboboxMode' });

    // The textarea blurs when an option is clicked from the dropdown suggestions, in which case we don't want to
    // trigger the behaviour for the user having left the textarea completely, hence the `ignoreBlur` boolean.
    const handleBlur = () => {
      if (!ignoreBlur) {
        dispatch({ type: 'exitComboboxMode' });
        return;
      }
      dispatch({ type: 'setIgnoreBlur', payload: false });
    };

    const selectSuggestion = (suggestion) => {
      const { current: currentInput } = inputRef;
      const { indexOfAutocompleteStart: indexOfSearchStart } =
        getAutocompleteWordData({
          textArea: currentInput,
          triggerCharacter,
        });

      const currentSearchTerm = currentInput.value.substring(
        indexOfSearchStart,
        currentInput.selectionStart,
      );

      // We try to update the textArea with document.execCommand (so that the change is added to undo queue),
      // which requires the contentEditable attribute to be true. The value is later toggled back to 'false'.
      currentInput.contentEditable = 'true';
      // Input blurs when user clicks an option with the mouse
      currentInput.focus();
      currentInput.setSelectionRange(
        indexOfSearchStart,
        indexOfSearchStart + currentSearchTerm.length,
      );

      try {
        document.execCommand(
          'insertText',
          false,
          `${triggerCharacter}${suggestion.value} `,
        );
      } catch {
        // In the event of any error using execCommand, we make sure the text area updates (but undo queue will not)
        const { value: currentValue } = currentInput;
        const newTextAreaValue = `${currentValue.substring(
          0,
          indexOfSearchStart,
        )}${triggerCharacter}${suggestion.value}${currentValue.substring(
          indexOfSearchStart + currentSearchTerm.length,
        )} `;
        currentInput.value = newTextAreaValue;
      }

      currentInput.contentEditable = 'false';

      // Clear suggestions
      dispatch({ type: 'exitComboboxMode' });
    };

    const comboboxProps = isComboboxMode
      ? {
          role: 'combobox',
          'aria-haspopup': 'listbox',
          'aria-expanded': isComboboxMode,
          'aria-owns': `${id}-listbox`,
          'aria-activedescendant': `${id}-suggestion-${activeDescendentIndex}`,
        }
      : {};

    return (
      <div
        ref={wrapperRef}
        className={`c-autocomplete ${autoResize ? ' h-100' : ''}`}
        data-testid="autocomplete-wrapper"
      >
        {/* We use an assertive live region to alert screen reader users typing will now result in a search */}
        <span className="screen-reader-only" aria-live="assertive">
          {isComboboxMode ? searchInstructionsMessage : ''}
        </span>

        <textarea
          {...inputProps}
          {...comboboxProps}
          id={id}
          data-gramm_editor="false"
          ref={mergeInputRefs([inputRef, forwardedRef])}
          onChange={(e) => {
            onChange?.(e);
            handleInputChange(e);
          }}
          onBlur={(e) => {
            onBlur?.(e);
            handleBlur();
          }}
          onKeyDown={handleKeyDown}
          onClick={handleTextAreaClicked}
        />
        {isComboboxMode && !suppressPopover
          ? createPortal(
              <div
                ref={popoverRef}
                className="c-autocomplete__popover absolute"
                id={`${id}-autocomplete-popover`}
                style={{
                  top: `calc(${dropdownPositionPoints.y}px + ${DROPDOWN_VERTICAL_OFFSET}`,
                  left: `${dropdownPositionPoints.x}px`,
                }}
              >
                {suggestions && suggestions.length > 0 ? (
                  <ul className="list-none" role="listbox" id={`${id}-listbox`}>
                    {suggestions.map((suggestion, index) => (
                      // Disabled as the key handler is attached to the textarea
                      // eslint-disable-next-line jsx-a11y/click-events-have-key-events
                      <li
                        key={`${id}-suggestion-${index}`}
                        id={`${id}-suggestion-${index}`}
                        role="option"
                        aria-selected={index === activeDescendentIndex}
                        className="c-autocomplete__option flex items-center"
                        onClick={() => selectSuggestion(suggestion)}
                        onMouseDown={() =>
                          dispatch({ type: 'setIgnoreBlur', payload: true })
                        }
                      >
                        <UserListItemContent {...suggestion} />
                      </li>
                    ))}
                  </ul>
                ) : (
                  <span className="c-autocomplete__empty">
                    {emptyStateMessage}
                  </span>
                )}
              </div>,
              document.querySelector('body'),
            )
          : null}
      </div>
    );
  },
);
