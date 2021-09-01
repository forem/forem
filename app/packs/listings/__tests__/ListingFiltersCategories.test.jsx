import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ListingFiltersCategories } from '../components/ListingFiltersCategories';

describe('<ListingFiltersCategories />', () => {
  beforeEach(() => {
    global.selectNavigation = jest.fn();
  });

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

  const categories = [firstCategory, secondCategory, thirdCategory];
  const getProps = () => ({
    categories,
    category: 'clojure',
    onClick: jest.fn(),
  });

  const renderListingFilterCategories = (props = getProps()) =>
    render(<ListingFiltersCategories {...props} />);

  it('should have no a11y violations', async () => {
    const { container } = renderListingFilterCategories();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  describe('should render manage, create and all listings', () => {
    it('should render an all link', () => {
      const { getByText } = renderListingFilterCategories();

      const allLink = getByText(/all listings/i, { selector: 'a' });
      expect(allLink.getAttribute('href')).toEqual('/listings');
    });

    it('should be "selected" when there is no category selected', () => {
      const propsWithoutCategory = { ...getProps(), category: '' };
      const { queryByTestId } = renderListingFilterCategories(
        propsWithoutCategory,
      );

      expect(queryByTestId('selected')).toBeDefined();
    });
  });

  describe('should render all the categories links', () => {
    it('should render the categories name and their respective links', () => {
      const { getByText } = renderListingFilterCategories();
      categories.forEach((category) => {
        const categoryLink = getByText(`${category.name}`, { selector: 'a' });
        expect(categoryLink.getAttribute('href')).toEqual(
          `/listings/${category.slug}`,
        );
        expect(categoryLink.textContent).toEqual(category.name);
      });
    });

    it('should show a "selected" category where necessary', () => {
      const { getByTestId } = renderListingFilterCategories();
      const selectedCategory = getByTestId('selected-category');
      expect(selectedCategory.textContent).toEqual(firstCategory.name);
    });
  });
});
