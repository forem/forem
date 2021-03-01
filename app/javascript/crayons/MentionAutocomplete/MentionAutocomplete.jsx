import { h, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
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
 *
 * @example
 * <MentionAutocomplete
 *    startText="name"
 *    onSelect={(user) => console.log(user)}
 *    fetchSuggestions={fetchUsersByUsername}
 * />
 */
export const MentionAutocomplete = ({
  startText = '',
  onSelect,
  fetchSuggestions,
}) => {
  const [searchTerm, setSearchTerm] = useState(startText);
  const [cachedSearches, setCachedSearches] = useState({});
  const [users, setUsers] = useState([]);

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

  return (
    <Combobox
      aria-label="mention user"
      onSelect={(item) => onSelect(item)}
      className="crayons-autocomplete"
    >
      <ComboboxInput
        onChange={(e) => setSearchTerm(e.target.value)}
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
};
