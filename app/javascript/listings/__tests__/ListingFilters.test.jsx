import { h } from 'preact';
import render from 'preact-render-to-json';
import ListingFilters from '../components/ListingFilters';

describe('<ListingFilters />', () => {
  const firstCategory = {
    slug: 'clojure',
    name: 'Clojure',
  };

  const secondCategory = {
    slug: 'illa-iara-ques-htyashsayas-6kj8',
    name: 'Go',
  };

  const thirdCategory = {
    slug: 'alle-bece-tzehj-htyashsayas-7jh9',
    name: 'csharp',
  };

  const getCategories = () => [firstCategory, secondCategory, thirdCategory];
  const getTags = () => ['clojure', 'java', 'dotnet'];

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
