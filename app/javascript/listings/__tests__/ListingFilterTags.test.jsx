import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import ListingFiltersTags from '../components/ListingFiltersTags';

describe('<ListingFilterTags />', () => {
  const getTags = () => ['clojure', 'java', 'dotnet'];

  const getProps = () => ({
    message: 'Some message',
    onKeyUp: jest.fn(),
    onClearQuery: jest.fn(),
    onRemoveTag: jest.fn(),
    onKeyPress: jest.fn(),
    query: 'some-string&this=1',
    tags: getTags(),
  });

  const renderListingFilterTags = (props = getProps()) =>
    render(<ListingFiltersTags {...props} />);

  it('should have no a11y violations', async () => {
    const { container } = renderListingFilterTags();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  describe('should render a search field', () => {
    it('should have "search" as placeholder', () => {
      const { getByPlaceholderText } = renderListingFilterTags();
      getByPlaceholderText(/search/i);
    });

    it(`should have "${getProps().message}" as default value`, () => {
      const { getByDisplayValue } = renderListingFilterTags();
      getByDisplayValue(getProps().message);
    });

    it('should have auto-complete as off', () => {
      const { getByPlaceholderText } = renderListingFilterTags();
      const input = getByPlaceholderText(/search/i);
      expect(input.getAttribute('autoComplete')).toBe('off');
    });
  });

  describe('<ClearQueryButton />', () => {
    it('should render the clear query button', () => {
      const { getByTestId } = renderListingFilterTags();
      getByTestId('clear-query-button');
    });

    it('should not render the clear query button', () => {
      const propsWithoutQuery = { ...getProps(), query: '' };
      const { queryByTestId } = renderListingFilterTags(
        propsWithoutQuery,
      );
      expect(queryByTestId('clear-query-button')).toBeNull();
    });
  });

  describe('<SelectedTags />', () => {
    it('should render the selected Tags', () => {
      const { getByText } = renderListingFilterTags();
      getTags().forEach((tag) => {
        getByText(`${tag}`);
      });
    });
  });
});
