import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
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
    onKeyUp: jest.fn(),
    onClearQuery: jest.fn(),
    onRemoveTag: jest.fn(),
    onKeyPress: jest.fn(),
    query: 'some-string&this=1',
    categories: getCategories(),
    tags: getTags(),
  });

  const renderListingFilters = (props = getProps()) =>
    render(<ListingFilters {...props} />);

  it('should have no a11y violations', async () => {
    const { container } = renderListingFilters();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render the correct elements', () => {
    const { getByText } = renderListingFilters();
    expect(context).toMatchSnapshot();
  });
});
