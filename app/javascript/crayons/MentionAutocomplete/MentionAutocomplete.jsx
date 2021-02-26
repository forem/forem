import { h, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import {
  Combobox,
  ComboboxInput,
  ComboboxPopover,
  ComboboxList,
  ComboboxOption,
} from '@reach/combobox';
import '@reach/combobox/styles.css';

function fetchUsers(searchTerm) {
  const exampleApiResult = {
    result: [
      {
        username: 'one',
        name: 'User One',
        profile_image_90: 'https://placedog.net/50',
      },
      {
        username: 'two',
        name: 'User Two',
        profile_image_90: 'https://placedog.net/51',
      },
    ],
  };

  return exampleApiResult.result.filter((user) =>
    user.username.includes(searchTerm),
  );
}

function useUsernameSearch(searchTerm) {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    if (searchTerm.trim() !== '') {
      let isFresh = true;

      // TODO: This fetch should actually be an awaited network call
      const fetchedUsers = fetchUsers(searchTerm);
      if (isFresh) setUsers(fetchedUsers);

      return () => (isFresh = false);
    }
  }, [searchTerm]);

  return users;
}

const UserListItemContent = ({ user }) => {
  return (
    <Fragment>
      <span className="crayons-avatar crayons-avatar--l mr-2">
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

export const MentionAutocomplete = ({ startText = '', onSelect }) => {
  const [searchTerm, setSearchTerm] = useState(startText);
  const users = useUsernameSearch(searchTerm);

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
