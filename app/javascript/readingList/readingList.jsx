import { h, Component } from 'preact';
import { PropTypes } from 'preact-compat';
import debounce from 'lodash.debounce';

import {
  defaultState,
  loadNextPage,
  onSearchBoxType,
  performInitialSearch,
  search,
  toggleTag,
  clearSelectedTags,
} from '../searchableItemList/searchableItemList';

import SnackBar from './snackbar';
import SideBar from './sidebar';
import ItemsContainer from './itemsContainer';

const STATUS_VIEW_VALID = 'valid';
const STATUS_VIEW_ARCHIVED = 'archived';
const READING_LIST_ARCHIVE_PATH = '/readinglist/archive';
const READING_LIST_PATH = '/readinglist';

export class ReadingList extends Component {
  constructor(props) {
    super(props);

    const { availableTags, statusView } = this.props;
    this.state = defaultState({ availableTags, archiving: false, statusView });

    // bind and initialize all shared functions
    this.onSearchBoxType = debounce(onSearchBoxType.bind(this), 300, {
      leading: true,
    });
    this.loadNextPage = loadNextPage.bind(this);
    this.performInitialSearch = performInitialSearch.bind(this);
    this.search = search.bind(this);
    this.toggleTag = toggleTag.bind(this);
    this.clearSelectedTags = clearSelectedTags.bind(this);
  }

  componentDidMount() {
    const { hitsPerPage, statusView } = this.state;

    this.performInitialSearch({
      containerId: 'reading-list',
      indexName: 'SecuredReactions',
      searchOptions: {
        hitsPerPage,
        filters: `status:${statusView}`,
      },
    });
  }

  setArchiveButtonLabel() {
    return this.isStatusViewValid() ? 'archive' : 'unarchive';
  }

  getNewStatusView() {
    return this.isStatusViewValid() ? STATUS_VIEW_ARCHIVED : STATUS_VIEW_VALID;
  }

  getNewPath() {
    return this.isStatusViewValid()
      ? READING_LIST_ARCHIVE_PATH
      : READING_LIST_PATH;
  }

  setNewPath = newPath => {
    window.history.replaceState(null, null, newPath);
  };

  toggleStatusView = event => {
    event.preventDefault();

    const { query, selectedTags } = this.state;

    const newStatusView = this.getNewStatusView();
    const newPath = this.getNewPath();

    this.setState({ statusView: newStatusView, items: [] });

    this.search(query, {
      page: 0,
      tags: selectedTags,
      statusView: newStatusView,
    });

    this.setNewPath(newPath);
  };

  toggleArchiveStatus = (event, item) => {
    event.preventDefault();

    const { statusView, items, totalCount } = this.state;
    window.fetch(`/reading_list_items/${item.id}`, {
      method: 'PUT',
      headers: {
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ current_status: statusView }),
      credentials: 'same-origin',
    });

    const newItems = items;
    newItems.splice(newItems.indexOf(item), 1);
    this.setState({
      archiving: true,
      items: newItems,
      totalCount: totalCount - 1,
    });

    this.hideSnackBar(1000);
  };

  hideSnackBar(time) {
    setTimeout(() => {
      this.setState({ archiving: false });
    }, time);
  }

  isStatusViewValid() {
    const { statusView } = this.state;
    return statusView === STATUS_VIEW_VALID;
  }

  render() {
    const {
      items,
      itemsLoaded,
      totalCount,
      availableTags,
      selectedTags,
      showLoadMoreButton,
      archiving,
      query,
    } = this.state;

    const archiveButtonLabel = this.setArchiveButtonLabel();

    return (
      <div className="home item-list">
        <SideBar
          onSearchBoxType={onSearchBoxType}
          isStatusViewValid={this.isStatusViewValid()}
          selectedTags={selectedTags}
          clearSelectedTags={clearSelectedTags}
          availableTags={availableTags}
          toggleTag={this.toggleTag}
          toggleStatusView={this.toggleStatusView}
        />
        <ItemsContainer
          itemsLoaded={itemsLoaded}
          items={items}
          archiveButtonLabel={archiveButtonLabel}
          toggleArchiveStatus={this.toggleArchiveStatus}
          selectedTags={selectedTags}
          query={query}
          showLoadMoreButton={showLoadMoreButton}
          loadNextPage={this.loadNextPage}
          totalCount={totalCount}
          isStatusViewValid={this.isStatusViewValid}
        />
        <SnackBar
          archiving={archiving}
          isStatusViewValid={this.isStatusViewValid()}
        />
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
