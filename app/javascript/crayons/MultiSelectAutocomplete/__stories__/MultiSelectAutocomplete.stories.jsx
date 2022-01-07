import { h } from 'preact';
import { MultiSelectAutocomplete } from '../MultiSelectAutocomplete';

export default {
  title: 'BETA/MultiSelectAutocomplete',
  argTypes: {
    border: {
      table: {
        defaultValue: { summary: false },
      },
      description: 'Display as a standard bordered input',
    },
    labelText: {
      description: 'The label for the input',
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
    <MultiSelectAutocomplete {...args} fetchSuggestions={fetchSuggestions} />
  );
};

Default.args = {
  border: true,
  labelText: 'Example multi select autocomplete',
};

Default.story = {
  name: 'default',
};
