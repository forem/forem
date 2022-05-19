import { h } from 'preact';
import { useRef, useLayoutEffect, useReducer } from 'preact/hooks';
import { forwardRef } from 'preact/compat';
// TODO: let this be passed in as a template like multi
import { UserListItemContent } from './UserListItemContent';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';

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

// TODO: Use case 1: No existing text area e.g. EditorBody
// Test with VoiceOver
// Refactor of UserListItemContent props / pass in as template
// Markdown insertion is broken

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

    const { setTextArea } = useTextAreaAutoResize();

    useLayoutEffect(() => {
      if (autoResize && inputRef.current) {
        setTextArea(inputRef.current);
      }
    }, [autoResize, setTextArea]);

    const handleInputChange = () => {
      const { current: currentInput } = inputRef;
      const {
        isUserMention: isSearching,
        indexOfMentionStart: indexOfSearchStart,
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
        fetchSuggestions(searchTerm).then((suggestions) =>
          dispatch({ type: 'setSuggestions', payload: suggestions }),
        );

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
        relativeToElement: wrapperRef.current,
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
      const { indexOfMentionStart: indexOfSearchStart } =
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
        //   TODO: test both cases
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
          'aria-expanded': suggestions.length > 0,
          'aria-owns': `${id}-listbox`,
        }
      : {};

    return (
      <div
        ref={wrapperRef}
        className={`c-autocomplete relative${autoResize ? ' h-100' : ''}`}
      >
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
        />
        {isComboboxMode && !suppressPopover ? (
          <div
            ref={popoverRef}
            className="c-autocomplete__popover absolute"
            id={`${id}-autocomplete-popover`}
            style={{
              top: `calc(${dropdownPositionPoints.y}px + ${DROPDOWN_VERTICAL_OFFSET}`,
              left: `${dropdownPositionPoints.x}px`,
            }}
          >
            {suggestions.length > 0 ? (
              <ul className="list-none" role="listbox" id={`${id}-listbox`}>
                {suggestions.map((suggestion, index) => (
                  // Disabled as the key handler is attached to the textarea
                  // eslint-disable-next-line jsx-a11y/click-events-have-key-events
                  <li
                    key={`${id}-suggestion-${index}`}
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
              <span className="c-autocomplete__empty">{emptyStateMessage}</span>
            )}
          </div>
        ) : null}
      </div>
    );
  },
);
