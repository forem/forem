import { h } from 'preact';

import { ItemListTags } from '../src/components/ItemList/ItemListTags';

const SideBar = ({
  onSearchBoxType,
  isStatusViewValid,
  selectedTags,
  clearSelectedTags,
  availableTags,
  toggleTag,
  toggleStatusView,
}) => {
  return (
    <div className="side-bar">
      <div className="widget filters">
        <input onKeyUp={onSearchBoxType} placeHolder="search your list" />
        <div className="filters-header">
          <h4 className="filters-header-text">my tags</h4>
          {Boolean(selectedTags.length) && (
            <a
              className="filters-header-action"
              href={
                isStatusViewValid
                  ? READING_LIST_PATH
                  : READING_LIST_ARCHIVE_PATH
              }
              onClick={clearSelectedTags}
              data-no-instant
            >
              clear all
            </a>
          )}
        </div>
        <ItemListTags
          availableTags={availableTags}
          selectedTags={selectedTags}
          onClick={toggleTag}
        />

        <div className="status-view-toggle">
          <a
            href={READING_LIST_ARCHIVE_PATH}
            onClick={e => toggleStatusView(e)}
            data-no-instant
          >
            {isStatusViewValid ? 'View Archive' : 'View Reading List'}
          </a>
        </div>
      </div>
    </div>
  );
};

export default SideBar;
