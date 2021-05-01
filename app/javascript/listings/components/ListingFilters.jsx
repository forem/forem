import { h } from 'preact';
import PropTypes from 'prop-types';
import { ListingFiltersCategories } from './ListingFiltersCategories';
import { ListingFiltersTags } from './ListingFiltersTags';

export const ListingFilters = ({
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
    <div className="crayons-layout__sidebar-left">
      <ListingFiltersTags
        message={message}
        onKeyUp={onKeyUp}
        onClearQuery={onClearQuery}
        onRemoveTag={onRemoveTag}
        tags={tags}
        onKeyPress={onKeyPress}
        query={query}
      />
      <ListingFiltersCategories
        categories={categories}
        category={category}
        onClick={onSelectCategory}
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
