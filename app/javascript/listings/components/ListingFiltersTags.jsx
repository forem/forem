import { h } from 'preact';
import PropTypes from 'prop-types';
import { ClearQueryButton } from './ClearQueryButton';
import { SelectedTags } from './SelectedTags';

export const ListingFiltersTags = ({
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
    <div className="relative pb-2 m:pb-6 px-2 m:px-0">
      <input
        type="text"
        placeholder="Search..."
        id="listings-search"
        aria-label="Search listings"
        autoComplete="off"
        className="crayons-textfield"
        defaultValue={message}
        onKeyUp={onKeyUp}
      />
      {shouldRenderClearQueryButton && (
        <ClearQueryButton onClick={onClearQuery} />
      )}
      <SelectedTags
        tags={tags}
        onRemoveTag={onRemoveTag}
        onKeyPress={onKeyPress}
      />
    </div>
  );
};

ListingFiltersTags.propTypes = {
  message: PropTypes.string.isRequired,
  onKeyUp: PropTypes.func.isRequired,
  onClearQuery: PropTypes.func.isRequired,
  onRemoveTag: PropTypes.func.isRequired,
  onKeyPress: PropTypes.func.isRequired,
  tags: PropTypes.arrayOf(PropTypes.string).isRequired,
  query: PropTypes.string.isRequired,
};
