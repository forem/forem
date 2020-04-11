import { h } from 'preact';
import PropTypes from 'prop-types';
import CategoryLinks from "./categoryLinks";

const ClassifiedFiltersCategories = ({ allCategories, category, onClick }) => (
  <div className="classified-filters-categories">
    <a
      href="/listings"
      className={category === '' ? 'selected' : ''}
      onClick={(e) => onClick(e, '')}
      data-no-instant
    >
      all
    </a>
    <CategoryLinks categories={allCategories} onClick={onClick} />
    <a href="/listings/new" className="classified-create-link">
      Create a Listing
    </a>
    <a href="/listings/dashboard" className="classified-create-link">
      Manage Listings
    </a>
  </div>
);

ClassifiedFiltersCategories.propTypes = {
  allCategories: PropTypes.isRequired,
  onClick: PropTypes.func.isRequired,
  category: PropTypes.isRequired,
};

export default ClassifiedFiltersCategories;
