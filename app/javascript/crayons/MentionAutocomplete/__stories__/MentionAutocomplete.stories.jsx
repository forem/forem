import { h } from 'preact';
import { MentionAutocomplete } from '../MentionAutocomplete';
import notes from './mention-autocomplete.md';

export default {
  title: 'Components/MentionAutocomplete',
  parameters: { notes },
};

function fetchUsers(searchTerm) {
  const exampleApiResult = {
    result: [
      {
        username: 'one',
        name: 'User One First Name Last Name',
        profile_image_90: '/images/apple-icon.png',
      },
      {
        username: 'two',
        name: 'User Two',
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

export const Default = () => (
  <div>
    <MentionAutocomplete onSelect={() => {}} fetchSuggestions={fetchUsers} />
  </div>
);

Default.story = {
  name: 'default',
};
