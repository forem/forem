import { h } from 'preact';
import PropTypes from 'prop-types';
import { tagPropTypes } from '../../common-prop-types';
import ClearQueryButton from './ClearQueryButton';
import SelectedTags from './SelectedTags';

const ListingFiltersTags = ({
  message,
  onKeyUp,
  onClearQuery,
  onRemoveTag,
  onKeyPress,
  query,
  tags,
}) => {
  const shouldRenderClearQueryButton = query.length > 0;

  return (
    <div className="listing-filters-tags" id="listing-filters-tags">
      <input
        type="text"
        placeholder="search"
        id="listings-search"
        autoComplete="off"
        defaultValue={message}
        onKeyUp={onKeyUp}
      />
      {shouldRenderClearQueryButton && (
        <ClearQueryButton onClick={onClearQuery} />
      )}
      <SelectedTags tags={tags} onClick={onRemoveTag} onKeyPress={onKeyPress} />
    </div>
  );
};

ListingFiltersTags.propTypes = {
  message: PropTypes.string.isRequired,
  onKeyUp: PropTypes.func.isRequired,
  onClearQuery: PropTypes.func.isRequired,
  onRemoveTag: PropTypes.func.isRequired,
  onKeyPress: PropTypes.func.isRequired,
  tags: PropTypes.arrayOf(tagPropTypes).isRequired,
  query: PropTypes.string.isRequired,
};

export default ListingFiltersTags;
