import { h, Fragment } from 'preact';
import { useState, useEffect, useRef, useLayoutEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import {
  Combobox,
  ComboboxInput,
  ComboboxPopover,
  ComboboxList,
  ComboboxOption,
} from '@reach/combobox';
import '@reach/combobox/styles.css';
import { getMentionWordData, getCursorXY } from '@utilities/textAreaUtils';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';

const MIN_SEARCH_CHARACTERS = 2;
const MAX_RESULTS_DISPLAYED = 6;

/**
 * Helper function to copy all styles and attributes from the original textarea to new autocomplete textarea before removing the original node
 *
 * @param {element} originalNodeToReplace The DOM element that should be replaced
 * @param {element} newNode The DOM element that will receive all attributes and styles of the original node.
 */
const replaceTextArea = (originalNodeToReplace, newNode) => {
  // Make sure all attributes are copied to the autocomplete textarea
  const attributes = originalNodeToReplace.attributes;
  Object.keys(attributes).forEach((attributeKey) => {
    newNode.setAttribute(
      attributes[attributeKey].name,
      attributes[attributeKey].value,
    );
  });

  // Make sure all styles are copied to the autocomplete textarea
  newNode.style.cssText = document.defaultView.getComputedStyle(
    originalNodeToReplace,
    '',
  ).cssText;
  // Make sure no transition replays when the new textarea is mounted
  newNode.style.transition = 'none';

  // We need to manually remove the element, as Preact's diffing algorithm won't replace it in render
  originalNodeToReplace.remove();
  newNode.focus();
};

const UserListItemContent = ({ user }) => {
  return (
    <Fragment>
      <span className="crayons-avatar crayons-avatar--l mr-2 shrink-0">
        <img
          src={user.profile_image_90}
          alt=""
          className="crayons-avatar__image "
        />
      </span>

      <div>
        <p className="crayons-autocomplete__name">{user.name}</p>
        <p className="crayons-autocomplete__username">{`@${user.username}`}</p>
      </div>
    </Fragment>
  );
};

/**
 * A component for dynamically searching for users and displaying results in a dropdown.
 * This component will replace the textarea passed in props, copying all styles and attributes, and allowing for progressive enhancement
 *
 * @param {object} props
 * @param {element} props.replaceElement The textarea DOM element that should be replaced
 * @param {function} props.fetchSuggestions The async call to use for the search
 *
 * @example
 * <MentionAutocompleteCombobox
 *    replaceElement={textAreaRef.current}
 *    fetchSuggestions={fetchUsersByUsername}
 * />
 */
export const MentionAutocompleteTextArea = ({
  replaceElement,
  fetchSuggestions,
}) => {
  const [textContent, setTextContent] = useState('');
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

  const isSmallScreen = useMediaQuery(`(max-width: ${BREAKPOINTS.Small}px)`);

  const inputRef = useRef(null);
  const popoverRef = useRef(null);

  useEffect(() => {
    if (searchTerm.length < MIN_SEARCH_CHARACTERS) {
      return;
    }

    if (cachedSearches[searchTerm]) {
      setUsers(cachedSearches[searchTerm]);
      return;
    }

    fetchSuggestions(searchTerm).then(({ result: fetchedUsers }) => {
      const resultLength = Math.min(fetchedUsers.length, MAX_RESULTS_DISPLAYED);

      const results = fetchedUsers.slice(0, resultLength);

      setCachedSearches({
        ...cachedSearches,
        [searchTerm]: results,
      });

      setUsers(results);

      // Let screen reader users know a list has populated
      if (!ariaHelperText && fetchedUsers.length > 0) {
        setAriaHelperText(`Mention user, ${fetchedUsers.length} results found`);
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
      }
    };

    document.addEventListener('click', closeOnClickOutsideListener);

    return () =>
      document.removeEventListener('click', closeOnClickOutsideListener);
  }, [searchTerm]);

  useLayoutEffect(() => {
    const { current: input } = inputRef;
    input.focus();
    input.setSelectionRange(cursorPosition, cursorPosition - 1);
  }, [cursorPosition]);

  const handleTextInputChange = ({ target: { value } }) => {
    setTextContent(value);
    const { isUserMention, indexOfMentionStart } = getMentionWordData(
      inputRef.current,
    );

    const { selectionStart } = inputRef.current;

    if (isUserMention) {
      // search term begins after the @ character
      const searchTermStartPosition = indexOfMentionStart + 1;

      const mentionText = value.substring(
        searchTermStartPosition,
        selectionStart,
      );

      const { x: cursorX, y } = getCursorXY(
        inputRef.current,
        indexOfMentionStart,
      );
      const textAreaX = inputRef.current.offsetLeft;

      // On small screens always show dropdown at start of textarea
      const dropdownX = isSmallScreen ? textAreaX : cursorX;

      setDropdownPositionPoints({ x: dropdownX, y });
      setSearchTerm(mentionText);
      setSelectionInsertIndex(searchTermStartPosition);
    } else if (searchTerm) {
      // User has moved away from an in-progress @mention - clear current search
      setSearchTerm('');
      setAriaHelperText('');
      setUsers([]);
    }
  };

  const handleSelect = (username) => {
    // Construct the new textArea content with selected username inserted
    const textWithSelection = `${textContent.substring(
      0,
      selectionInsertIndex,
    )}${username} ${textContent.substring(inputRef.current.selectionStart)}`;

    // Clear the current search
    setSearchTerm('');
    setUsers([]);
    setAriaHelperText('');

    // Update the text area value
    setTextContent(textWithSelection);

    // Update the cursor to directly after the selection (+2 accounts for the @ sign, and adding a space after the username)
    const newCursorPosition = selectionInsertIndex + username.length + 2;
    setCursorPosition(newCursorPosition);
  };

  useLayoutEffect(() => {
    if (inputRef.current) {
      // Replace the whole textarea passed in props with the autocomplete textarea
      replaceTextArea(replaceElement, inputRef.current);
    }
  }, [replaceElement]);

  return (
    <Fragment>
      <div aria-live="polite" class="screen-reader-only">
        {ariaHelperText}
      </div>
      <Combobox
        id="combobox-container"
        onSelect={handleSelect}
        className="crayons-autocomplete"
      >
        <ComboboxInput
          ref={inputRef}
          value={textContent}
          data-mention-autocomplete-active="true"
          as="textarea"
          autocomplete={false}
          onChange={handleTextInputChange}
        />
        {searchTerm && (
          <ComboboxPopover
            ref={popoverRef}
            className="crayons-autocomplete__popover absolute"
            id="mention-autocomplete-popover"
            style={{
              top: `calc(${dropdownPositionPoints.y}px + 1.5rem)`,
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
};

MentionAutocompleteTextArea.propTypes = {
  replaceElement: PropTypes.node.isRequired,
  fetchSuggestions: PropTypes.func.isRequired,
};
