import { h, Fragment } from 'preact';
import { useState, useEffect, useRef, useLayoutEffect } from 'preact/hooks';
import { forwardRef } from 'preact/compat';
import PropTypes from 'prop-types';
import {
  Combobox,
  ComboboxInput,
  ComboboxPopover,
  ComboboxList,
  ComboboxOption,
} from '@reach/combobox';
import { UserListItemContent } from './UserListItemContent';
import {
  getMentionWordData,
  getCursorXY,
  useTextAreaAutoResize,
} from '@utilities/textAreaUtils';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';

const MIN_SEARCH_CHARACTERS = 2;
const MAX_RESULTS_DISPLAYED = 6;
// Used to ensure dropdown appears just below search text
const DROPDOWN_VERTICAL_OFFSET = '1.5rem';

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

/**
 * Helper function to copy all styles and attributes from the original textarea to new autocomplete textareas before removing the original node
 *
 * @param {object} options
 * @param {element} options.originalNodeToReplace The DOM element that should be replaced
 * @param {element} options.plainTextArea The DOM element to be used in the 'non-autosuggest' state. It will receive all attributes and styles of the original node.
 * @param {element} options.comboboxTextArea The DOM element to be used in the 'autosuggest' state. It will receive all attributes and styles of the original node.
 */
const replaceTextArea = ({
  originalNodeToReplace,
  plainTextArea,
  comboboxTextArea,
}) => {
  const newNodes = [plainTextArea, comboboxTextArea];

  const { attributes } = originalNodeToReplace;
  const { cssText } = document.defaultView.getComputedStyle(
    originalNodeToReplace,
    '',
  );

  newNodes.forEach((node) => {
    // Make sure all attributes are copied to the autocomplete & plain textareas
    Object.keys(attributes).forEach((attributeKey) => {
      node.setAttribute(
        attributes[attributeKey].name,
        attributes[attributeKey].value,
      );
    });

    // Make sure all styles are copied to the autocomplete & plain textareas
    node.style.cssText = cssText;
    // Make sure no transition replays when the new textareas are mounted
    node.style.transition = 'none';
    // Copy any initial value
    node.value = originalNodeToReplace.value;
  });

  // We need to manually remove the original element, as Preact's diffing algorithm won't replace it in render
  originalNodeToReplace.remove();
};

/**
 * A component for dynamically searching for users and displaying results in a dropdown.
 * This component will optionally replace the textarea passed in props, copying all styles and attributes, and allowing for progressive enhancement.
 * The component functions by switching between a normal textarea and a combobox textarea. Both textareas receive the attributes and styles of the replaceElement prop, and only one is presented at a time.
 * A ref may be given to the component, which will be forwarded to the new textarea
 *
 * @param {object} props
 * @param {element} props.replaceElement The textarea DOM element that should be replaced
 * @param {function} props.fetchSuggestions The async call to use for the search
 * @param {object} props.inputProps Any additional props to be attached to the textarea element
 *
 * @example
 * <MentionAutocompleteCombobox
 *    replaceElement={textAreaRef.current}
 *    fetchSuggestions={fetchUsersByUsername}
 * />
 */

export const MentionAutocompleteTextArea = forwardRef(
  (
    { replaceElement, fetchSuggestions, autoResize = false, ...inputProps },
    forwardedRef,
  ) => {
    const [textContent, setTextContent] = useState(
      inputProps.defaultValue ? inputProps.defaultValue : '',
    );
    const [searchTerm, setSearchTerm] = useState('');
    const [cachedSearches, setCachedSearches] = useState({});
    const [dropdownPositionPoints, setDropdownPositionPoints] = useState({
      x: 0,
      y: 0,
    });
    const [selectionInsertIndex, setSelectionInsertIndex] = useState(0);
    const [users, setUsers] = useState([]);
    const [cursorPosition, setCursorPosition] = useState(null);
    const [ariaHelperText, setAriaHelperText] = useState('');
    const [focusable, setFocusable] = useState(false);

    const isSmallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Small}px)`);

    const plainTextAreaRef = useRef(null);
    const comboboxRef = useRef(null);
    const popoverRef = useRef(null);
    const containerRef = useRef(null);

    const { setTextArea, setAdditionalElements } = useTextAreaAutoResize();

    const {
      onChange,
      onBlur,
      id: inputId,
      ...autocompleteInputProps
    } = inputProps;

    useLayoutEffect(() => {
      if (autoResize && comboboxRef.current && plainTextAreaRef.current) {
        setTextArea(plainTextAreaRef.current);
        setAdditionalElements([comboboxRef.current, containerRef.current]);
      }
    }, [autoResize, setTextArea, setAdditionalElements]);

    useEffect(() => {
      if (searchTerm.length < MIN_SEARCH_CHARACTERS) {
        return;
      }

      if (cachedSearches[searchTerm]) {
        setUsers(cachedSearches[searchTerm]);
        return;
      }

      fetchSuggestions(searchTerm).then(({ result: fetchedUsers }) => {
        // If the fetchSuggestion call yields more than the MAX, truncate the results
        const resultLength = Math.min(
          fetchedUsers.length,
          MAX_RESULTS_DISPLAYED,
        );

        const results = fetchedUsers.slice(0, resultLength);

        setCachedSearches({
          ...cachedSearches,
          [searchTerm]: results,
        });

        setUsers(results);

        // Let screen reader users know a list has populated
        if (!ariaHelperText && fetchedUsers.length > 0) {
          setAriaHelperText(
            `Mention user, ${fetchedUsers.length} results found`,
          );
        }
      });
    }, [searchTerm, fetchSuggestions, cachedSearches, ariaHelperText]);

    useLayoutEffect(() => {
      const popover = popoverRef.current;
      if (!popover) {
        return;
      }

      const closeOnClickOutsideListener = (event) => {
        if (!popover.contains(event.target)) {
          // User clicked outside, reset to not searching state
          setSearchTerm('');
          setAriaHelperText('');
          setUsers([]);

          const { selectionStart } = comboboxRef.current;

          // Switch back to the plain text area
          comboboxRef.current.classList.add('hidden');
          plainTextAreaRef.current.classList.remove('hidden');
          setCursorPosition(selectionStart + 1);
        }
      };

      document.addEventListener('click', closeOnClickOutsideListener);

      return () =>
        document.removeEventListener('click', closeOnClickOutsideListener);
    }, [searchTerm]);

    useLayoutEffect(() => {
      const { current: plainTextInput } = plainTextAreaRef;
      const { current: combobox } = comboboxRef;

      const activeInput = combobox.classList.contains('hidden')
        ? plainTextInput
        : combobox;

      if (
        focusable ||
        document.activeElement === combobox ||
        document.activeElement === plainTextInput
      ) {
        // Check if the currently focused element is one of the mention autocomplete's
        // inputs. This check is necessary to prevent an issue in iOS browsers only.
        // An additional check to see if the component can be focusable
        // covers the use case for clicking on elements in the mention autocomplete list.
        activeInput.focus();
        activeInput.setSelectionRange(cursorPosition, cursorPosition - 1);
        setFocusable(true);
      }
    }, [cursorPosition, focusable]);

    const handleTextInputChange = ({ target: { value } }) => {
      setTextContent(value);
      const isComboboxVisible = !comboboxRef.current.classList.contains(
        'hidden',
      );
      const currentActiveInput = isComboboxVisible
        ? comboboxRef.current
        : plainTextAreaRef.current;

      const { isUserMention, indexOfMentionStart } = getMentionWordData(
        currentActiveInput,
      );

      const { selectionStart } = currentActiveInput;

      if (isUserMention) {
        // search term begins after the @ character
        const searchTermStartPosition = indexOfMentionStart + 1;

        const mentionText = value.substring(
          searchTermStartPosition,
          selectionStart,
        );

        const { x: cursorX, y } = getCursorXY(
          currentActiveInput,
          indexOfMentionStart,
        );
        const textAreaX = currentActiveInput.offsetLeft;

        // On small screens always show dropdown at start of textarea
        const dropdownX = isSmallScreen ? textAreaX : cursorX;

        setDropdownPositionPoints({ x: dropdownX, y });
        setSearchTerm(mentionText);
        setSelectionInsertIndex(searchTermStartPosition);

        if (!isComboboxVisible) {
          // This is the start of a fresh search, transfer use from plain textarea to combobox
          comboboxRef.current.classList.remove('hidden');
          plainTextAreaRef.current.classList.add('hidden');
          setCursorPosition(selectionStart + 1);
        }
      } else if (searchTerm) {
        // User has moved away from an in-progress @mention - clear current search
        setSearchTerm('');
        setAriaHelperText('');
        setUsers([]);

        if (isComboboxVisible) {
          // Search has ended, transfer use from combobox back to plain textarea
          comboboxRef.current.classList.add('hidden');
          plainTextAreaRef.current.classList.remove('hidden');
          setCursorPosition(selectionStart + 1);
        }
      }
    };

    const handleComboboxBlur = () => {
      // User has left the textarea, exit combobox functionality without refocusing plainTextArea
      comboboxRef.current.classList.add('hidden');
      plainTextAreaRef.current.classList.remove('hidden');
    };

    const handleSelect = (username) => {
      // Construct the new textArea content with selected username inserted
      const textWithSelection = `${textContent.substring(
        0,
        selectionInsertIndex,
      )}${username} ${textContent.substring(
        comboboxRef.current.selectionStart,
      )}`;

      // Clear the current search
      setSearchTerm('');
      setUsers([]);
      setAriaHelperText('');

      // Update the text area value
      setTextContent(textWithSelection);

      // Switch back to the plain text input
      comboboxRef.current.classList.add('hidden');
      plainTextAreaRef.current.classList.remove('hidden');

      // Allow any other attached change event to receive the updated text
      onChange?.(textWithSelection);

      // Update the cursor to directly after the selection (+2 accounts for the @ sign, and adding a space after the username)
      const newCursorPosition = selectionInsertIndex + username.length + 2;
      setCursorPosition(newCursorPosition);
    };

    useLayoutEffect(() => {
      const { current: comboboxTextArea } = comboboxRef;
      const { current: plainTextArea } = plainTextAreaRef;

      if (comboboxTextArea && plainTextArea && replaceElement) {
        replaceTextArea({
          originalNodeToReplace: replaceElement,
          plainTextArea,
          comboboxTextArea,
        });
        plainTextArea.focus();
      }

      // Initialize the new text areas in the "non-autosuggest" state, hiding the combobox until a search begins
      comboboxTextArea.classList.add('hidden');
    }, [replaceElement]);

    return (
      <Fragment>
        <div aria-live="polite" class="screen-reader-only">
          {ariaHelperText}
        </div>

        <Combobox
          ref={containerRef}
          id="combobox-container"
          data-testid="autocomplete-wrapper"
          onSelect={handleSelect}
          className={`crayons-autocomplete${autoResize ? ' h-100' : ''}`}
        >
          <ComboboxInput
            {...autocompleteInputProps}
            aria-label="Mention user"
            ref={comboboxRef}
            value={textContent}
            data-mention-autocomplete-active="true"
            as="textarea"
            autocomplete={false}
            onChange={(e) => {
              onChange?.(e);
              handleTextInputChange(e);
            }}
            onBlur={(e) => {
              onBlur?.(e);
              handleComboboxBlur();
            }}
          />

          <textarea
            {...autocompleteInputProps}
            id={inputId}
            data-mention-autocomplete-active="true"
            ref={mergeInputRefs([plainTextAreaRef, forwardedRef])}
            onChange={(e) => {
              onChange?.(e);
              handleTextInputChange(e);
            }}
            value={textContent}
          />

          {searchTerm && (
            <ComboboxPopover
              ref={popoverRef}
              className="crayons-autocomplete__popover absolute"
              id="mention-autocomplete-popover"
              style={{
                top: `calc(${dropdownPositionPoints.y}px + ${DROPDOWN_VERTICAL_OFFSET}`,
                left: `${dropdownPositionPoints.x}px`,
              }}
            >
              {users.length > 0 ? (
                <ComboboxList>
                  {users.map((user) => (
                    <ComboboxOption
                      value={user.username}
                      className="crayons-autocomplete__option flex items-center"
                    >
                      <UserListItemContent user={user} />
                    </ComboboxOption>
                  ))}
                </ComboboxList>
              ) : (
                <span className="crayons-autocomplete__empty">
                  {searchTerm.length >= MIN_SEARCH_CHARACTERS
                    ? 'No results found'
                    : 'Type to search for a user'}
                </span>
              )}
            </ComboboxPopover>
          )}
        </Combobox>
      </Fragment>
    );
  },
);

MentionAutocompleteTextArea.propTypes = {
  replaceElement: PropTypes.node,
  fetchSuggestions: PropTypes.func.isRequired,
  autoResize: PropTypes.bool,
};
