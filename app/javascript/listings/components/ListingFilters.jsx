import { h } from 'preact';
import PropTypes from 'prop-types';
import ListingFiltersCategories from './ListingFiltersCategories';
import ListingFiltersTags from './ListingFiltersTags';

const ListingFilters = ({
  categories,
  category,
  onSelectCategory,
  message,
  onKeyUp,
  onClearQuery,
  onRemoveTag,
  tags,
  onKeyPress,
  query,
}) => {
  return (
    <div className="listing-filters" id="listing-filters">
      <ListingFiltersCategories
        categories={categories}
        category={category}
        onClick={onSelectCategory}
      />
      <ListingFiltersTags
        message={message}
        onKeyUp={onKeyUp}
        onClearQuery={onClearQuery}
        onRemoveTag={onRemoveTag}
        tags={tags}
        onKeyPress={onKeyPress}
        query={query}
      />
    </div>
  );
};

ListingFilters.propTypes = {
  categories: PropTypes.shape({
    slug: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
  }).isRequired,
  category: PropTypes.string.isRequired,
  onSelectCategory: PropTypes.func.isRequired,
  message: PropTypes.isRequired,
  onKeyUp: PropTypes.func.isRequired,
  onClearQuery: PropTypes.func.isRequired,
  onRemoveTag: PropTypes.func.isRequired,
  tags: PropTypes.arrayOf(PropTypes.string).isRequired,
  onKeyPress: PropTypes.func.isRequired,
  query: PropTypes.string.isRequired,
};

export default ListingFilters;
