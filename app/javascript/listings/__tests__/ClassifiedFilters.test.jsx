import { h } from 'preact';
import render from 'preact-render-to-json';
import ClassifiedFilters from '../components/ClassifiedFilters';

describe('<ClassifiedFilters />', () => {
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

  const renderClassifiedFilters = (props = getProps()) =>
    render(<ClassifiedFilters {...props} />);

  it('Should match the snapshot', () => {
    const context = renderClassifiedFilters();
    expect(context).toMatchSnapshot();
  });
});
