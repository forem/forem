import { h } from 'preact';
import PropTypes from 'prop-types';
import CategoryLinks from './CategoryLinks';

const ListingFiltersCategories = ({ categories, category, onClick }) => (
  <div className="listing-filters-categories">
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
      className="listing-create-link"
    >
      Create a Listing
    </a>
    <a
      id="listings-dashboard-link"
      href="/listings/dashboard"
      className="listing-create-link"
    >
      Manage Listings
    </a>
  </div>
);

ListingFiltersCategories.propTypes = {
  categories: PropTypes.isRequired,
  onClick: PropTypes.func.isRequired,
  category: PropTypes.isRequired,
};

export default ListingFiltersCategories;
