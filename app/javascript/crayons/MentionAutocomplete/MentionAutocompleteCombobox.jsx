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

// @ sign + 2 chars
const MIN_SEARCH_CHARACTERS = 3;
const MAX_RESULTS_DISPLAYED = 6;

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
 * This component should be mounted when a user has started typing a mention with the '@' symbol, and will be positioned at the given coordinates.
 *
 * @param {object} props
 * @param {string} props.startText The initial search term to use
 * @param {function} props.onSelect Callback function for using the selected user
 * @param {function} props.fetchSuggestions The async call to use for the search
 * @param {object} props.placementCoords The x/y coordinates for placement of the popover and input. Used to position the invisible combobox input over the current cursor placement (to avoid scroll jumps on focus), and the dropdown under it.
 * @param {function} props.onSearchTermChange A callback for each time the searchTerm changes
 *
 * @example
 * <MentionAutocompleteCombobox
 *    startText="name"
 *    onSelect={handleUserMentionSelection}
 *    fetchSuggestions={fetchUsersByUsername}
 *    placementCoords={{x: 22, y: 0}}
 *    onSearchTermChange={updateSearchTermText}
 * />
 */
export const MentionAutocompleteCombobox = ({ replaceElement }) => {
  // const [searchTerm, setSearchTerm] = useState('@');
  // const [cachedSearches, setCachedSearches] = useState({});
  // const [users, setUsers] = useState([]);

  // const inputRef = useRef(null);

  // useEffect(() => {
  //   if (searchTerm.length >= MIN_SEARCH_CHARACTERS) {
  //     // Remove the '@' symbol for search
  //     const trimmedSearchTerm = searchTerm.substring(1);

  //     if (cachedSearches[trimmedSearchTerm]) {
  //       setUsers(cachedSearches[trimmedSearchTerm]);
  //       return;
  //     }

  //     fetchSuggestions(trimmedSearchTerm).then(({ result: fetchedUsers }) => {
  //       const resultLength = Math.min(
  //         fetchedUsers.length,
  //         MAX_RESULTS_DISPLAYED,
  //       );

  //       const results = fetchedUsers.slice(0, resultLength);

  //       setCachedSearches({
  //         ...cachedSearches,
  //         [trimmedSearchTerm]: results,
  //       });
  //       setUsers(results);
  //     });
  //   }
  // }, [searchTerm, fetchSuggestions, cachedSearches]);

  // useEffect(() => {
  //   inputRef.current.focus();
  // }, [inputRef]);

  // useLayoutEffect(() => {
  //   const popover = document.getElementById('mention-autocomplete-popover');
  //   if (!popover) {
  //     return;
  //   }

  //   const closeOnClickOutsideListener = (event) => {
  //     if (!popover.contains(event.target)) {
  //       // User clicked outside, exit with current search term
  //       onSelect(searchTerm);
  //     }
  //   };

  //   document.addEventListener('click', closeOnClickOutsideListener);

  //   return () =>
  //     document.removeEventListener('click', closeOnClickOutsideListener);
  // }, [searchTerm, onSelect]);

  // const handleSearchTermChange = (event) => {
  //   const {
  //     target: { value },
  //   } = event;

  //   if (value.charAt(value.length - 1) === ' ' || value === '') {
  //     // User has spaced away from a complete word or deleted everything - finish the autocomplete
  //     onSelect(value);
  //     return;
  //   }
  //   setSearchTerm(value);
  //   onSearchTermChange(value);
  // };

  useLayoutEffect(() => {
    if (inputRef.current) {
      const attributes = replaceElement.attributes;
      Object.keys(attributes).forEach((attributeKey) => {
        inputRef.current.setAttribute(
          attributes[attributeKey].name,
          attributes[attributeKey].value,
        );
      });

      // We need to manually remove the element, as Preact's diffing algorithm won't replace it in render
      replaceElement.remove();
      inputRef.current.focus();
    }
  }, [replaceElement]);

  const inputRef = useRef(null);

  return (
    <Combobox
      aria-label="mention user"
      id="combobox-container"
      onSelect={(item) => console.log('selected', item)}
      className="crayons-autocomplete"
    >
      <ComboboxInput
        ref={inputRef}
        data-mention-autocomplete-active="true"
        as="textarea"
        selectOnClick
        autocomplete={false}
      />
      <ComboboxPopover
        className="crayons-autocomplete__popover"
        id="mention-autocomplete-popover"
      >
        <ComboboxList>
          <ComboboxOption
            value="one"
            className="crayons-autocomplete__option flex items-center"
          ></ComboboxOption>
        </ComboboxList>
      </ComboboxPopover>
    </Combobox>
  );
};

MentionAutocompleteCombobox.propTypes = {
  onSelect: PropTypes.func.isRequired,
  fetchSuggestions: PropTypes.func.isRequired,
  placementCoords: PropTypes.shape({
    x: PropTypes.number,
    y: PropTypes.number,
  }).isRequired,
  onSearchTermChange: PropTypes.func.isRequired,
};
