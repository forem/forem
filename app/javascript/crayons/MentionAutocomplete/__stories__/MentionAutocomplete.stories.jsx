import { h } from 'preact';
import { MentionAutocomplete } from '../MentionAutocomplete';

export default {
  title: 'Components/MentionAutocomplete',
};

function fetchUsers(searchTerm) {
  const exampleApiResult = {
    result: [
      {
        username: 'one',
        name: 'First name Last Name One Two Three',
        profile_image_90: 'https://placedog.net/50',
      },
      {
        username: 'two',
        name: 'User Two',
        profile_image_90: 'https://placedog.net/51',
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
