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
 * @param {object} props.placementCoords The x/y coordinates for placement of the popover
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
export const MentionAutocompleteCombobox = ({
  onSelect,
  fetchSuggestions,
  placementCoords,
  onSearchTermChange,
}) => {
  const [searchTerm, setSearchTerm] = useState('@');
  const [cachedSearches, setCachedSearches] = useState({});
  const [users, setUsers] = useState([]);

  const inputRef = useRef(null);

  useEffect(() => {
    if (searchTerm.length >= 3) {
      // Remove the '@' symbol for search
      const trimmedSearchTerm = searchTerm.substring(1);

      if (cachedSearches[trimmedSearchTerm]) {
        setUsers(cachedSearches[trimmedSearchTerm]);
        return;
      }

      fetchSuggestions(trimmedSearchTerm).then((fetchedUsers) => {
        setCachedSearches({
          ...cachedSearches,
          [trimmedSearchTerm]: fetchedUsers,
        });
        setUsers(fetchedUsers);
      });
    }
  }, [searchTerm, fetchSuggestions, cachedSearches]);

  useEffect(() => {
    inputRef.current.focus();
  }, [inputRef]);

  useLayoutEffect(() => {
    const popover = document.getElementById('mention-autocomplete-popover');
    if (!popover) {
      return;
    }

    const closeOnClickOutsideListener = (event) => {
      if (!popover.contains(event.target)) {
        // User clicked outside, exit with current search term
        onSelect(searchTerm);
      }
    };

    document.addEventListener('click', closeOnClickOutsideListener);

    return () =>
      document.removeEventListener('click', closeOnClickOutsideListener);
  }, [searchTerm, onSelect]);

  const handleSearchTermChange = (event) => {
    const {
      target: { value },
    } = event;

    if (value.charAt(value.length - 1) === ' ' || value === '') {
      // User has spaced away from a complete word or deleted everything - finish the autocomplete
      onSelect(value);
      return;
    }
    setSearchTerm(value);
    onSearchTermChange(value);
  };

  return (
    <Combobox
      aria-label="mention user"
      onSelect={(item) => onSelect(`@${item}`)}
      className="crayons-autocomplete"
    >
      <ComboboxInput
        style={{
          opacity: 0.000001,
        }}
        ref={inputRef}
        onChange={handleSearchTermChange}
        value={searchTerm}
        selectOnClick
        autocomplete={false}
      />
      <ComboboxPopover
        className="crayons-autocomplete__popover"
        id="mention-autocomplete-popover"
        style={{
          position: 'absolute',
          top: `calc(${placementCoords.y}px + 1.5rem)`,
          left: `${placementCoords.x}px`,
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
            {searchTerm.length >= 2
              ? 'No results found'
              : 'Type to search for a user'}
          </span>
        )}
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
