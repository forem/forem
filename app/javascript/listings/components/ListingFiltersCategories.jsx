import { h } from 'preact';
import PropTypes from 'prop-types';
import { CategoryLinks } from './CategoryLinks';
import { CategoryLinksMobile } from './CategoryLinksMobile';

export const ListingFiltersCategories = ({ categories, category, onClick }) => (
  <div className="listing-filters px-2 m:px-0" id="listing-filters">
    <nav className="hidden m:block">
      <a
        id="listings-link"
        href="/listings"
        className={`crayons-link crayons-link--block ${
          category === '' ? 'crayons-link--current' : ''
        }`}
        data-testid={category === '' ? 'selected' : ''}
        onClick={onClick}
        data-no-instant
      >
        All listings
      </a>
      <CategoryLinks
        categories={categories}
        onClick={onClick}
        selectedCategory={category}
      />
    </nav>
    <CategoryLinksMobile categories={categories} selectedCategory={category} />
  </div>
);

ListingFiltersCategories.propTypes = {
  categories: PropTypes.arrayOf(
    PropTypes.shape({
      slug: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  category: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
};
