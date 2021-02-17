import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { debounceAction } from '../utilities/debounceAction';

import {
  defaultState,
  loadNextPage,
  onSearchBoxType,
  performInitialSearch,
  search,
  toggleTag,
  clearSelectedTags,
} from '../searchableItemList/searchableItemList';
import { ItemListItem } from './components/ItemListItem';
import { ItemListItemArchiveButton } from './components/ItemListItemArchiveButton';
import { ItemListLoadMoreButton } from './components/ItemListLoadMoreButton';
import { ItemListTags } from './components/ItemListTags';
import { Button } from '@crayons';
import { request } from '@utilities/http';

const STATUS_VIEW_VALID = 'valid,confirmed';
const STATUS_VIEW_ARCHIVED = 'archived';
const READING_LIST_ARCHIVE_PATH = '/readinglist/archive';
const READING_LIST_PATH = '/readinglist';

const FilterText = ({ selectedTags, query, value }) => {
  return (
    <h2 className="fw-bold fs-l">
      {selectedTags.length === 0 && query.length === 0
        ? value
        : 'Nothing with this filter 🤔'}
    </h2>
  );
};

export class ReadingList extends Component {
  constructor(props) {
    super(props);

    const { statusView } = this.props;
    this.state = defaultState({ archiving: false, statusView });

    // bind and initialize all shared functions
    this.onSearchBoxType = debounceAction(onSearchBoxType.bind(this), {
      leading: true,
    });
    this.loadNextPage = loadNextPage.bind(this);
    this.performInitialSearch = performInitialSearch.bind(this);
    this.search = search.bind(this);
    this.toggleTag = toggleTag.bind(this);
    this.clearSelectedTags = clearSelectedTags.bind(this);
  }

  componentDidMount() {
    const { statusView } = this.state;

    this.performInitialSearch({
      searchOptions: { status: `${statusView}` },
    });
  }

  toggleStatusView = (event) => {
    event.preventDefault();

    const { query, selectedTags } = this.state;

    const isStatusViewValid = this.statusViewValid();
    const newStatusView = isStatusViewValid
      ? STATUS_VIEW_ARCHIVED
      : STATUS_VIEW_VALID;
    const newPath = isStatusViewValid
      ? READING_LIST_ARCHIVE_PATH
      : READING_LIST_PATH;

    // empty items so that changing the view will start from scratch
    this.setState({ statusView: newStatusView, items: [] });

    this.search(query, {
      page: 0,
      tags: selectedTags,
      statusView: newStatusView,
    });

    // change path in the address bar
    window.history.replaceState(null, null, newPath);
  };

  toggleArchiveStatus = (event, item) => {
    event.preventDefault();

    const { statusView, items, totalCount } = this.state;
    request(`/reading_list_items/${item.id}`, {
      method: 'PUT',
      body: { current_status: statusView },
    });

    const t = this;
    const newItems = items;
    newItems.splice(newItems.indexOf(item), 1);
    t.setState({
      archiving: true,
      items: newItems,
      totalCount: totalCount - 1,
    });

    // hide the snackbar in a few moments
    setTimeout(() => {
      t.setState({ archiving: false });
    }, 1000);
  };

  statusViewValid() {
    const { statusView } = this.state;
    return statusView === STATUS_VIEW_VALID;
  }

  renderEmptyItems() {
    const { itemsLoaded, selectedTags, query } = this.state;

    if (itemsLoaded && this.statusViewValid()) {
      return (
        <div className="align-center p-9 py-10 color-base-80">
          <FilterText
            selectedTags={selectedTags}
            query={query}
            value="Your reading list is empty"
          />
          <p class="color-base-60 pt-2">
            Click the{' '}
            <span class="fw-bold">
              bookmark reaction
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                className="crayons-icon mx-1"
                xmlns="http://www.w3.org/2000/svg"
                role="img"
              >
                <path d="M5 2h14a1 1 0 011 1v19.143a.5.5 0 01-.766.424L12 18.03l-7.234 4.536A.5.5 0 014 22.143V3a1 1 0 011-1zm13 2H6v15.432l6-3.761 6 3.761V4z" />
              </svg>
            </span>
            when viewing a post to add it to your reading list.
          </p>
        </div>
      );
    }

    return (
      <div className="align-center p-9 py-10 color-base-80">
        <FilterText
          selectedTags={selectedTags}
          query={query}
          value="Your Archive is empty..."
        />
      </div>
    );
  }

  render() {
    const {
      items,
      totalCount,
      availableTags,
      selectedTags,
      showLoadMoreButton,
      archiving,
    } = this.state;

    const isStatusViewValid = this.statusViewValid();

    const archiveButtonLabel = isStatusViewValid ? 'Archive' : 'Unarchive';
    const itemsToRender = items.map((item) => {
      return (
        <ItemListItem item={item}>
          <ItemListItemArchiveButton
            text={archiveButtonLabel}
            onClick={(e) => this.toggleArchiveStatus(e, item)}
          />
        </ItemListItem>
      );
    });

    const snackBar = archiving ? (
      <div className="snackbar">
        {isStatusViewValid ? 'Archiving...' : 'Unarchiving...'}
      </div>
    ) : (
      ''
    );
    return (
      <div>
        <header className="crayons-layout flex justify-between items-center pb-0">
          <h1 class="crayons-title">
            {isStatusViewValid ? 'Reading list' : 'Archive'}
            {` (${totalCount > 0 ? totalCount : '0'})`}
          </h1>

          <div class="flex items-center">
            <Button
              onClick={(e) => this.toggleStatusView(e)}
              className="mr-2 whitespace-nowrap"
              variant="outlined"
              url={READING_LIST_ARCHIVE_PATH}
              tagName="a"
              data-no-instant
            >
              {isStatusViewValid ? 'View archive' : 'View reading list'}
            </Button>
            <input
              aria-label="Search..."
              onKeyUp={this.onSearchBoxType}
              placeholder="Search..."
              className="crayons-textfield"
            />
          </div>
        </header>

        <div className="crayons-layout crayons-layout--2-cols">
          <ItemListTags
            availableTags={availableTags}
            selectedTags={selectedTags}
            onClick={this.toggleTag}
          />

          <main className="crayons-layout__content">
            <div className="crayons-card mb-4">
              {items.length > 0 ? itemsToRender : this.renderEmptyItems()}
            </div>

            <ItemListLoadMoreButton
              show={showLoadMoreButton}
              onClick={this.loadNextPage}
            />
          </main>

          {snackBar}
        </div>
      </div>
    );
  }
}

ReadingList.defaultProps = {
  statusView: STATUS_VIEW_VALID,
};

ReadingList.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  statusView: PropTypes.oneOf([STATUS_VIEW_VALID, STATUS_VIEW_ARCHIVED]),
};

FilterText.propTypes = {
  selectedTags: PropTypes.arrayOf(PropTypes.string).isRequired,
  value: PropTypes.string.isRequired,
  query: PropTypes.arrayOf(PropTypes.string).isRequired,
};
