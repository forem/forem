import { h, createRef, render } from 'preact';
import { MentionAutocompleteTextArea } from '../MentionAutocompleteTextArea';
import notes from './mention-autocomplete.md';

export default {
  title: 'Components/MentionAutocompleteTextArea',
  parameters: { notes },
};

async function fetchUsers(searchTerm) {
  const exampleApiResult = [
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
  ];

  return {
    result: exampleApiResult.filter((user) =>
      user.username.includes(searchTerm),
    ),
  };
}

export const Default = () => {
  const textAreaRef = createRef(null);

  return (
    <div id="story-container">
      <label id="storybook-autocomplete-label">
        Enter text and type '@us' to start triggering search results
        <div>
          <textarea
            ref={textAreaRef}
            aria-labelledby="storybook-autocomplete-label"
            onFocus={() => {
              if (textAreaRef.current) {
                const container = document.getElementById('story-container');
                const storybookElement = textAreaRef.current;

                render(
                  <MentionAutocompleteTextArea
                    replaceElement={storybookElement}
                    fetchSuggestions={fetchUsers}
                    labelId="storybook-autocomplete-label"
                  />,
                  container,
                  storybookElement,
                );
              }
            }}
            style={{
              width: '500px',
              maxWidth: '100%',
              minHeight: '200px',
            }}
          />
        </div>
      </label>
    </div>
  );
};

Default.story = {
  name: 'default',
};
