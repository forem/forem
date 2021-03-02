import { h, Fragment } from 'preact';
import { useState, useEffect, useRef } from 'preact/hooks';
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
 *
 * @param {object} props
 * @param {string} props.startText The initial search term to use
 * @param {function} props.onSelect Callback function for using the selected user
 * @param {function} props.fetchSuggestions The async call to use for the search
 * @param {object} props.placementCoords The x/y coordinates for placement of the popover
 * @param {function} props.onSearchTermChange A callback for each time the searchTerm changes
 *
 * @example
 * <MentionAutocomplete
 *    startText="name"
 *    onSelect={(user) => console.log(user)}
 *    fetchSuggestions={fetchUsersByUsername}
 *    placementCoords={{x: 22, y: 0}}
 *    onSearchTermChange={updateSearchTermText}
 * />
 */
export const MentionAutocomplete = ({
  startText = '',
  onSelect,
  fetchSuggestions,
  placementCoords,
  onSearchTermChange,
}) => {
  const [searchTerm, setSearchTerm] = useState(startText);
  const [cachedSearches, setCachedSearches] = useState({});
  const [users, setUsers] = useState([]);

  const inputRef = useRef(null);

  useEffect(() => {
    if (searchTerm.trim() !== '') {
      if (cachedSearches[searchTerm]) {
        setUsers(cachedSearches[searchTerm]);
        return;
      }

      fetchSuggestions(searchTerm).then((fetchedUsers) => {
        setCachedSearches({ ...cachedSearches, [searchTerm]: fetchedUsers });
        setUsers(fetchedUsers);
      });
    }
  }, [searchTerm, fetchSuggestions, cachedSearches]);

  useEffect(() => {
    inputRef.current.focus();
  }, [inputRef]);

  return (
    <Combobox
      aria-label="mention user"
      onSelect={(item) => onSelect(item)}
      className="crayons-autocomplete"
      style={{
        position: 'absolute',
        top: `${placementCoords.y}px`,
        left: `${placementCoords.x}px`,
      }}
    >
      <ComboboxInput
        style={{
          opacity: 0.000001,
        }}
        ref={inputRef}
        onChange={(e) => {
          setSearchTerm(e.target.value);
          onSearchTermChange(e.target.value);
        }}
        selectOnClick
      />
      <ComboboxPopover className="crayons-autocomplete__popover">
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
          <span className="crayons-autocomplete__empty">No results found</span>
        )}
      </ComboboxPopover>
    </Combobox>
  );
};

MentionAutocomplete.propTypes = {
  startText: PropTypes.string,
  onSelect: PropTypes.func.isRequired,
  fetchSuggestions: PropTypes.func.isRequired,
  placementCoords: PropTypes.shape({
    x: PropTypes.number,
    y: PropTypes.number,
  }).isRequired,
  onSearchTermChange: PropTypes.func.isRequired,
};
