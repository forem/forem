import { h } from 'preact';
import { AutocompleteTriggerTextArea } from '@crayons';

export default {
  title: 'App Components/AutocompleteTriggerTextArea',
  argTypes: {
    id: {
      description: 'The input ID',
      control: {
        type: 'text',
      },
    },
    triggerCharacter: {
      description:
        'The character which will cause the textarea to enter "search mode"',
      control: {
        type: 'text',
      },
    },
    autoResize: {
      description:
        'Should the textarea resize in height as the text content grows (to avoid scrolling)',
      control: {
        type: 'boolean',
      },
      table: {
        defaultValue: { summary: false },
      },
    },
    maxSuggestions: {
      description: 'The maximum number of suggestions to show in the dropdown',
      control: {
        type: 'number',
      },
    },
    searchInstructionsMessage: {
      description: 'Text to instruct users on the autocomplete behaviour',
      control: {
        type: 'text',
      },
    },
    replaceElement: {
      description:
        'An optional textarea element that will be replaced by the autocomplete one, copying across all attributes and styles',
    },
    fetchSuggestions: {
      description:
        'The callback function which will provide autocomplete suggestions for the given search term',
    },
  },
};

const fakeUsers = [
  { id: 1, name: 'User 1', username: 'user_1' },
  { id: 2, name: 'User 2', username: 'user_2' },
  { id: 3, name: 'User 3', username: 'user_3' },
  { id: 4, name: 'User 4', username: 'user_4' },
  { id: 5, name: 'User 5', username: 'user_5' },
];

const fakeFetch = async (searchTerm) =>
  fakeUsers.filter(
    (user) =>
      user.name.toLowerCase().startsWith(searchTerm.toLowerCase()) ||
      user.username.startsWith(searchTerm.toLowerCase()),
  );

export const Default = (args) => (
  <div>
    <AutocompleteTriggerTextArea
      {...args}
      className="crayons-textfield"
      aria-label="Example autocomplete trigger text area"
      aria-describedby="explainer"
    />
    <p id="explainer">Start typing '@user' to see suggestions</p>
  </div>
);

Default.args = {
  id: 'storybook-autocomplete',
  triggerCharacter: '@',
  autoResize: false,
  searchInstructionsMessage: 'Type to search for a user',
  maxSuggestions: 5,
  replaceElement: undefined,
  fetchSuggestions: fakeFetch,
};
