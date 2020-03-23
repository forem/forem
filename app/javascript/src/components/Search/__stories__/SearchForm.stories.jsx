import { h } from 'preact';

import { action } from '@storybook/addon-actions';
import { SearchForm } from '..';

const commonProps = {
  searchBoxId: 'nav-search',
  onSearch: action('on preloading search'),
  onSubmitSearch: e => {
    e.preventDefault();
    action('on submit')(e);
  },
};

export default {
  component: SearchForm,
  title: 'App Components/Search/Search Form',
};

export const NoSearchTerm = () => <SearchForm {...commonProps} searchTerm="" />;
NoSearchTerm.story = {
  name: 'no search term',
};

export const WithSearchTerm = () => (
  <SearchForm {...commonProps} searchTerm="Hello" />
);
NoSearchTerm.story = {
  name: 'with search term',
};
