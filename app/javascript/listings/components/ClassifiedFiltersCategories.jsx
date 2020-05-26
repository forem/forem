import { h } from 'preact';
import PropTypes from 'prop-types';
import CategoryLinks from './CategoryLinks';

const ClassifiedFiltersCategories = ({ categories, category, onClick }) => (
  <div className="classified-filters-categories">
    <a
      id="listings-link"
      href="/listings"
      className={category === '' ? 'selected' : ''}
      onClick={onClick}
      data-no-instant
    >
      all
    </a>
    <CategoryLinks
      categories={categories}
      onClick={onClick}
      selectedCategory={category}
    />
    <a
      id="listings-new-link"
      href="/listings/new"
      className="classified-create-link"
    >
      Create a Listing
    </a>
    <a
      id="listings-dashboard-link"
      href="/listings/dashboard"
      className="classified-create-link"
    >
      Manage Listings
    </a>
  </div>
);

ClassifiedFiltersCategories.propTypes = {
  categories: PropTypes.arrayOf(
    PropTypes.shape({
      slug: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  category: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
};

export default ClassifiedFiltersCategories;
