import { h } from 'preact';
import { MultiSelectAutocomplete } from '../MultiSelectAutocomplete';

export default {
  title: 'BETA/MultiSelectAutocomplete',
};

export const Default = () => {
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
      labelText="Example multi select autocomplete"
      fetchSuggestions={fetchSuggestions}
    />
  );
};

Default.story = {
  name: 'default',
};
