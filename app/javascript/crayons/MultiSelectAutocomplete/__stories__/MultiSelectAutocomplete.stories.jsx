import { h } from 'preact';
import { MultiSelectAutocomplete } from '../MultiSelectAutocomplete';
import MultiSelectAutocompleteDoc from './MultiSelectAutocomplete.mdx';

export default {
  title: 'App Components/MultiSelectAutocomplete',
  parameters: {
    docs: {
      page: MultiSelectAutocompleteDoc,
    },
  },
  argTypes: {
    allowUserDefinedSelections: {
      table: {
        defaultValue: { summary: false },
      },
      description: 'Whether or not a user can create new options to select',
    },
    border: {
      table: {
        defaultValue: { summary: false },
      },
      description: 'Display as a standard bordered input',
    },
    labelText: {
      description: 'The label for the input',
    },
    showLabel: {
      description:
        'Should the label text be visible (it will always be available to assistive technology regardless)',
      table: {
        defaultValue: { summary: true },
      },
    },
    placeholder: {
      description:
        'Placeholder text, shown when no selections have been made yet',
    },
    maxSelections: {
      description: 'Optional maximum number of selections that can be made',
    },
    staticSuggestionsHeading: {
      description:
        'Optional heading to show when static suggestions are shown (when user has not yet typed a search term). Accepts either a string or an HTML element.',
    },
  },
};

export const Default = (args) => {
  const options = [
    { name: 'one' },
    { name: 'two' },
    { name: 'three' },
    { name: 'four' },
    { name: 'five' },
    { name: 'six' },
    { name: 'seven' },
    { name: 'eight' },
    { name: 'nine' },
    { name: 'ten' },
  ];

  const fetchSuggestions = async (searchTerm) =>
    options.filter((option) => option.name.startsWith(searchTerm));

  return (
    <MultiSelectAutocomplete
      {...args}
      fetchSuggestions={fetchSuggestions}
      staticSuggestions={options.slice(0, 3)}
    />
  );
};

Default.args = {
  border: true,
  labelText: 'Example multi select autocomplete',
  showLabel: true,
  placeholder: 'Add a number...',
  maxSelections: 4,
  staticSuggestionsHeading: 'Static suggestions',
  allowUserDefinedSelections: false,
};

Default.storyName = 'default';
