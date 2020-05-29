import { h } from 'preact';
import { deep } from 'preact-render-spy';
import ListingFiltersCategories from '../components/ListingFiltersCategories';

describe('<ListingFiltersCategories />', () => {
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
    onClick: () => {
      return 'onClick';
    },
  });

  const renderListingFilterCategories = (props = getProps()) =>
    deep(<ListingFiltersCategories {...props} />);

  describe('Should render the links to allow navigation', () => {
    const context = renderListingFilterCategories();

    it('Should render a link and a message relative to listings', () => {
      const listingsLink = context.find('#listings-link');

      expect(listingsLink.attr('href')).toBe('/listings');
      expect(listingsLink.attr('className')).toBe('');
      expect(listingsLink.text()).toBe('all');
    });

    it('When there\'s no category, the className of the listings link should be "selected"', () => {
      const propsWithoutCategory = { ...getProps(), category: '' };
      const contextWithoutCategory = renderListingFilterCategories(
        propsWithoutCategory,
      );

      const listingsLink = contextWithoutCategory.find('#listings-link');
      expect(listingsLink.attr('className')).toBe('selected');
    });

    it('Should render a link and a message relative to new listing', () => {
      const newListingLink = context.find('#listings-new-link');

      expect(newListingLink.attr('href')).toBe('/listings/new');
      expect(newListingLink.attr('className')).toBe('listing-create-link');
      expect(newListingLink.text()).toBe('Create a Listing');
    });

    it('Should render a link and a message relative to dashboard', () => {
      const dashboardLink = context.find('#listings-dashboard-link');

      expect(dashboardLink.attr('href')).toBe('/listings/dashboard');
      expect(dashboardLink.attr('className')).toBe('listing-create-link');
      expect(dashboardLink.text()).toBe('Manage Listings');
    });
  });

  describe('Should render categories links', () => {
    const context = renderListingFilterCategories();
    it('Should render the categories name and their respective links', () => {
      categories.forEach((category) => {
        const categoryLink = context.find(`#category-link-${category.slug}`);
        expect(categoryLink.attr('href')).toBe(`/listings/${category.slug}`);
        expect(categoryLink.text()).toBe(category.name);
      });
    });

    it('Should set the class of the category link as "selected" when category slug matches the selected category name', () => {
      const selectedCategoryLink = context.find(`.selected`);
      expect(selectedCategoryLink.attr('id')).toBe(
        `category-link-${firstCategory.slug}`,
      );
    });

    it('should set the class of the unselected categories as blank', () => {
      const unselectedCategories = categories.filter(
        (category) => category.slug !== getProps().category,
      );
      unselectedCategories.forEach((unselectedCategory) => {
        const unselectedCategoryLink = context.find(
          `#category-link-${unselectedCategory.slug}`,
        );
        expect(unselectedCategoryLink.attr('className')).toBe('');
      });
    });
  });
});
