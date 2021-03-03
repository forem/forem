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
        username: 'u_one',
        name: 'User One First Name Last Name',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'u_two',
        name: 'User Two',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'u_three',
        name: 'User Three',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'u_four',
        name: 'User Four',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'u_five',
        name: 'User Five',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'u_six',
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
      <textarea
        ref={textAreaRef}
        aria-label="test text area"
        style={{ width: '500px', maxWidth: '100%', minHeight: '200px' }}
      />
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
