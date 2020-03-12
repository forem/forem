import { h } from 'preact';
import { storiesOf } from '@storybook/react';
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

storiesOf('App Components/Search/Search Form', module)
  .add('No search term', () => <SearchForm {...commonProps} searchTerm="" />)
  .add('With search term', () => (
    <SearchForm {...commonProps} searchTerm="Hello" />
  ));
