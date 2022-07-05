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
  { id: 1, name: 'User 1' },
  { id: 2, name: 'User 2' },
  { id: 3, name: 'User 3' },
  { id: 4, name: 'User 4' },
  { id: 5, name: 'User 5' },
];

const fakeFetch = async (searchTerm) =>
  fakeUsers.filter((user) => user.name.startsWith(searchTerm));

export const Default = (args) => (
  <AutocompleteTriggerTextArea
    {...args}
    className="crayons-textfield"
    aria-label="Example autocomplete trigger text area"
  />
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
