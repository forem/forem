import { h } from 'preact';
import { MultiSelectAutocomplete } from '../MultiSelectAutocomplete';

export default {
  title: 'BETA/MultiSelectAutocomplete',
};

export const Default = () => {
  const options = [
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
  ];

  const fetchSuggestions = async (searchTerm) => {
    const filteredSuggestions = options.filter((option) =>
      option.startsWith(searchTerm),
    );

    return filteredSuggestions.length === 0
      ? [searchTerm]
      : filteredSuggestions;
  };

  return (
    <MultiSelectAutocomplete
      labelText="Example multi select autocomplete"
      fetchSuggestions={fetchSuggestions}
    />
  );
};

Default.story = {
  name: 'default',
};
