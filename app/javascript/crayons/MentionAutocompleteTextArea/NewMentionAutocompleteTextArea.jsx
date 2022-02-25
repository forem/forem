import { h } from 'preact';
import { useState, useRef, useLayoutEffect } from 'preact/hooks';
import { forwardRef } from 'preact/compat';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';

import {
  useTextAreaAutoResize,
  getMentionWordData,
  getCursorXY,
} from '@utilities/textAreaUtils';

// Used to ensure dropdown appears just below search text
const DROPDOWN_VERTICAL_OFFSET = '1.5rem';

// TODO: Use case 1: No existing text area e.g. EditorBody

/**
 * Helper function to merge any additional ref passed to the MentionAutocompleteTextArea with the inputRefs used internally by this component.
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

// Make this generic, accept a trigger character to enter suggesting mode, apply combobox attributes when this is typed
export const AutocompleteTriggerTextArea = forwardRef(
  (
    {
      id,
      triggerCharacter,
      cancelCharactersRegex,
      autoResize = false,
      onChange,
      fetchSuggestions,
      ...inputProps
    },
    forwardedRef,
  ) => {
    const [isComboboxMode, setIsComboboxMode] = useState(false);
    const [suggestions, setSuggestions] = useState([]);
    const [dropdownPositionPoints, setDropdownPositionPoints] = useState({
      x: 0,
      y: 0,
    });

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
      //   TODO: this should be more generic to any kind of trigger character
      // TODO: maybe consider cancel chars regex here too
      const { current: currentInput } = inputRef;
      const {
        isUserMention: isSearching,
        indexOfMentionStart: indexOfSearchStart,
      } = getMentionWordData(currentInput);

      setIsComboboxMode(isSearching);

      if (!isComboboxMode) {
        setSuggestions([]);
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

      fetchSuggestions(searchTerm).then((suggestions) =>
        setSuggestions(suggestions),
      );

      // Ensure dropdown is properly positioned
      const { x: cursorX, y } = getCursorXY({
        input: currentInput,
        selectionPoint: indexOfSearchStart,
        relativeToElement: wrapperRef.current,
      });
      const textAreaX = currentInput.offsetLeft;

      // On small screens always show dropdown at start of textarea
      const dropdownX = isSmallScreen ? textAreaX : cursorX;

      setDropdownPositionPoints({ x: dropdownX, y });
    };

    const handleKeyDown = ({ key }) => {
      // If we _are_ in suggest mode already:
      // - check if key is Esc, if so hide popover <-- do these things in a separate keydown
      // - if key is Up/Down arrow, set activedescendent
      // - if key is Enter, select current descendent (if exists)
      if (!isComboboxMode) {
        return;
      }
    };

    const comboboxProps = isComboboxMode
      ? {
          role: 'combobox',
          'aria-haspopup': 'listbox',
          'aria-expanded': 'false',
          'aria-owns': `${id}-listbox`,
        }
      : {};

    console.log(dropdownPositionPoints);

    return (
      <div
        ref={wrapperRef}
        className={`c-autocomplete relative${autoResize ? ' h-100' : ''}`}
      >
        <textarea
          {...inputProps}
          {...comboboxProps}
          data-gramm_editor="false"
          ref={mergeInputRefs([inputRef, forwardedRef])}
          onChange={(e) => {
            onChange?.(e);
            handleInputChange(e);
          }}
        />
        {suggestions.length > 0 ? (
          <div
            ref={popoverRef}
            className="c-autocomplete__popover absolute"
            id={`${id}-autocomplete-popover`}
            style={{
              top: `calc(${dropdownPositionPoints.y}px + ${DROPDOWN_VERTICAL_OFFSET}`,
              left: `${dropdownPositionPoints.x}px`,
            }}
          >
            <ul
              className="list-none"
              //   aria-labelledby="multi-select-label"
              role="listbox"
              id={`${id}-listbox`}
            >
              {suggestions.map(({ name }) => name)}
            </ul>
          </div>
        ) : null}
      </div>
    );
  },
);
