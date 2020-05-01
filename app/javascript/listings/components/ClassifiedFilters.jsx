import { h } from 'preact';
import PropTypes from 'prop-types';
import ClassifiedFiltersCategories from "./ClassifiedFiltersCategories";
import ClassifiedFiltersTags from "./ClassifiedFiltersTags";
import { tagPropTypes } from '../../src/components/common-prop-types';

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
  categories: PropTypes.isRequired,
  category: PropTypes.isRequired,
  onSelectCategory: PropTypes.func.isRequired,
  message: PropTypes.isRequired,
  onKeyUp: PropTypes.func.isRequired,
  onClearQuery: PropTypes.func.isRequired,
  onRemoveTag: PropTypes.func.isRequired,
  tags: PropTypes.arrayOf(tagPropTypes).isRequired,
  onKeyPress: PropTypes.func.isRequired,
  query: PropTypes.string.isRequired,
};

export default ClassifiedFilters;
