import { h } from 'preact';
import { PropTypes } from 'preact-compat';

import { ItemListItem } from '../src/components/ItemList/ItemListItem';
import { ItemListItemArchiveButton } from '../src/components/ItemList/ItemListItemArchiveButton';
import { ItemListLoadMoreButton } from '../src/components/ItemList/ItemListLoadMoreButton';

const ItemListItemContainer = ({
  items,
  archiveButtonLabel,
  toggleArchiveStatus,
}) => {
  return items.map(item => {
    return (
      <ItemListItem item={item}>
        <ItemListItemArchiveButton
          text={archiveButtonLabel}
          onClick={e => toggleArchiveStatus(e, item)}
        />
      </ItemListItem>
    );
  });
};

const FilterText = ({ selectedTags, query, value }) => {
  return (
    <h1>
      {selectedTags.length === 0 && query.length === 0
        ? value
        : 'Nothing with this filter 🤔'}
    </h1>
  );
};

const EmptyItems = ({ itemsLoaded, selectedTags, query }) => {
  if (itemsLoaded && isStatusViewValid) {
    return (
      <div className="items-empty">
        <FilterText
          selectedTags={selectedTags}
          query={query}
          value="Your Reading List is Lonely"
        />
        <h3>
          Hit the
          <span className="highlight">SAVE</span>
          or
          <span className="highlight">
            Bookmark
            <span role="img" aria-label="Bookmark">
              🔖
            </span>
          </span>
          to start your Collection
        </h3>
      </div>
    );
  }

  return (
    <div className="items-empty">
      <FilterText
        selectedTags={selectedTags}
        query={query}
        value="Your Archive List is Lonely"
      />
    </div>
  );
};

const ItemsContainer = ({
  itemsLoaded,
  items,
  archiveButtonLabel,
  toggleArchiveStatus,
  selectedTags,
  query,
  showLoadMoreButton,
  loadNextPage,
  totalCount,
  isStatusViewValid,
}) => {
  return (
    <div className="items-container">
      <div className={`results ${itemsLoaded ? 'results--loaded' : ''}`}>
        <div className="results-header">
          {isStatusViewValid ? 'Reading List' : 'Archive'}
          {` (${totalCount > 0 ? totalCount : 'empty'})`}
        </div>
        <div>
          {items.length > 0 ? (
            <ItemListItemContainer
              items={items}
              archiveButtonLabel={archiveButtonLabel}
              toggleArchiveStatus={toggleArchiveStatus}
            />
          ) : (
            <EmptyItems
              itemsLoaded={itemsLoaded}
              selectedTags={selectedTags}
              query={query}
            />
          )}
        </div>
      </div>
      <ItemListLoadMoreButton
        show={showLoadMoreButton}
        onClick={loadNextPage}
      />
    </div>
  );
};

FilterText.propTypes = {
  selectedTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  value: PropTypes.string.isRequired,
  query: PropTypes.arrayOf(PropTypes.string).isRequired,
};

EmptyItems.propTypes = {};

ItemsContainer.propTypes = {};

export default ItemsContainer;
