import { h } from 'preact';
import PropTypes from 'prop-types';
import ClassifiedFiltersCategories from './ClassifiedFiltersCategories';
import ClassifiedFiltersTags from './ClassifiedFiltersTags';

const ClassifiedFilters = ({
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
    <div className="classified-filters" id="classified-filters">
      <ClassifiedFiltersCategories
        categories={categories}
        category={category}
        onClick={onSelectCategory}
      />
      <ClassifiedFiltersTags
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

ClassifiedFilters.propTypes = {
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

export default ClassifiedFilters;
