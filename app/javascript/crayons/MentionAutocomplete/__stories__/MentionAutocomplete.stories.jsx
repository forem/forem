import { h, createRef, Fragment } from 'preact';
import notes from './mention-autocomplete.md';
import { MentionAutocomplete } from '@crayons/MentionAutocomplete';

export default {
  title: 'Components/MentionAutocomplete',
  parameters: { notes },
};

function fetchUsers(searchTerm) {
  const exampleApiResult = {
    result: [
      {
        username: 'user_one',
        name: 'User One First Name Last Name',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'user_two',
        name: 'User Two',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'user_three',
        name: 'User Three',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'user_four',
        name: 'User Four',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'user_five',
        name: 'User Five',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'user_six',
        name: 'User Six First Name Last Name Longer',
        profile_image_90: '/images/apple-icon.png',
      },
    ],
  };

  return Promise.resolve(
    exampleApiResult.result.filter((user) =>
      user.username.includes(searchTerm),
    ),
  );
}

export const Default = () => {
  const textAreaRef = createRef(null);
  return (
    <Fragment>
      <label style={{ display: 'flex', flexDirection: 'column' }}>
        Enter text and type '@us' to start triggering search results
        <textarea
          ref={textAreaRef}
          style={{ width: '500px', maxWidth: '100%', minHeight: '200px' }}
        />
      </label>

      <MentionAutocomplete
        textAreaRef={textAreaRef}
        fetchSuggestions={fetchUsers}
      />
    </Fragment>
  );
};

Default.story = {
  name: 'default',
};
