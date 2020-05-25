import { h } from 'preact';
import render from 'preact-render-to-json';
import ListingFilters from '../components/ListingFilters';

describe('<ListingFilters />', () => {
  const firstTag = {
    id: 1,
    tag: 'clojure',
  };
  const secondTag = {
    id: 2,
    tag: 'java',
  };
  const thirdTag = {
    id: 3,
    tag: 'dotnet',
  };

  const firstCategory = {
    id: 20,
    slug: 'clojure',
    name: 'Clojure',
  };

  const secondCategory = {
    id: 21,
    slug: 'illa-iara-ques-htyashsayas-6kj8',
    name: 'Go',
  };

  const thirdCategory = {
    id: 22,
    slug: 'alle-bece-tzehj-htyashsayas-7jh9',
    name: 'csharp',
  };

  const getCategories = () => [firstCategory, secondCategory, thirdCategory];
  const getTags = () => [firstTag, secondTag, thirdTag];

  const getProps = () => ({
    category: 'clojure',
    onSelectCategory: () => {
      return 'onSelectCategory';
    },
    message: 'some message',
    onKeyUp: () => {
      return 'onKeyUp';
    },
    onClearQuery: () => {
      return 'onClearQuery';
    },
    onRemoveTag: () => {
      return 'onRemoveTag';
    },
    onKeyPress: () => {
      return 'onKeyPress';
    },

    query: 'some-string&this=1',
    categories: getCategories(),
    tags: getTags(),
  });

  const renderListingFilters = (props = getProps()) =>
    render(<ListingFilters {...props} />);

  it('Should match the snapshot', () => {
    const context = renderListingFilters();
    expect(context).toMatchSnapshot();
  });
});
