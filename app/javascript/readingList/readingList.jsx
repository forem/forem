import { h, Component } from 'preact';
import { PropTypes } from 'preact-compat';
import debounce from 'lodash.debounce';
import setupAlgoliaIndex from '../src/utils/algolia';

import { ItemListItem } from '../src/components/ItemList/ItemListItem';
import { ItemListItemArchiveButton } from '../src/components/ItemList/ItemListItemArchiveButton';
import { ItemListLoadMoreButton } from '../src/components/ItemList/ItemListLoadMoreButton';
import { ItemListTags } from '../src/components/ItemList/ItemListTags';

const STATUS_VIEW_VALID = 'valid';
const STATUS_VIEW_ARCHIVED = 'archived';
const READING_LIST_ARCHIVE_PATH = '/readinglist/archive';
const READING_LIST_PATH = '/readinglist';

export class ReadingList extends Component {
  constructor(props) {
    super(props);

    this.handleTyping = debounce(this.handleTyping.bind(this), 300, {
      leading: true,
    });

    // this.archive = this.archive.bind(this);

    const { availableTags, statusView } = this.props;
    this.state = {
      query: '',
      index: null,

      page: 0,
      hitsPerPage: 1,
      totalCount: 0,

      items: [],
      itemsLoaded: false,

      availableTags,
      selectedTags: [],

      showLoadMoreButton: false,

      archiving: false,
      statusView,
    };
  }

  componentDidMount() {
    const index = setupAlgoliaIndex({
      containerId: 'reading-list',
      indexName: 'SecuredReactions',
    });

    // get default result set from Algolia
    const { hitsPerPage, statusView } = this.state;
    index
      .search('', { hitsPerPage, filters: `status:${statusView}` })
      .then(content => {
        this.setState({
          items: content.hits,
          totalCount: content.nbHits,
          index,
          itemsLoaded: true,
          showLoadMoreButton: content.hits.length === hitsPerPage,
        });
      });
  }

  handleTyping = e => {
    const query = e.target.value;
    const { selectedTags, statusView } = this.state;
    this.listSearch(query, selectedTags, statusView);
  };

  toggleTag = (e, tag) => {
    e.preventDefault();
    const { query, selectedTags, statusView } = this.state;
    const newTags = selectedTags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag);
    } else {
      newTags.splice(newTags.indexOf(tag), 1);
    }
    this.setState({ selectedTags: newTags, page: 0, items: [] });
    this.listSearch(query, newTags, statusView);
  };

  toggleStatusView = e => {
    e.preventDefault();
    const { statusView, query, selectedTags } = this.state;
    if (statusView === STATUS_VIEW_VALID) {
      this.setState({ statusView: STATUS_VIEW_ARCHIVED, page: 0, items: [] });
      this.listSearch(query, selectedTags, STATUS_VIEW_ARCHIVED);
      window.history.replaceState(null, null, READING_LIST_ARCHIVE_PATH);
    } else {
      this.setState({ statusView: STATUS_VIEW_VALID, page: 0, items: [] });
      this.listSearch(query, selectedTags, STATUS_VIEW_VALID);
      window.history.replaceState(null, null, READING_LIST_PATH);
    }
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

  loadNextPage = () => {
    const { statusView, query, selectedTags, page } = this.state;
    const isLoadMore = true;
    this.setState({ page: page + 1 });
    this.listSearch(query, selectedTags, statusView, isLoadMore);
  };

  listSearch(query, tags, statusView) {
    const { index, hitsPerPage, page, items } = this.state;
    const filters = { page, hitsPerPage, filters: `status:${statusView}` };
    if (tags.length > 0) {
      filters.tagFilters = tags;
    }
    index.search(query, filters).then(content => {
      const allItems = [...items, ...content.hits];

      this.setState({
        query,
        items: allItems,
        totalCount: content.nbHits,
        showLoadMoreButton: content.hits.length === hitsPerPage,
      });
    });
  }

  render() {
    const {
      archiving,
      availableTags,
      itemsLoaded,
      query,
      items,
      selectedTags,
      statusView,
      showLoadMoreButton,
      totalCount,
    } = this.state;

    const archiveButtonLabel =
      statusView === STATUS_VIEW_VALID ? 'archive' : 'unarchive';
    let allItems = items.map(item => {
      return (
        <ItemListItem item={item}>
          <ItemListItemArchiveButton
            text={archiveButtonLabel}
            onClick={e => this.toggleArchiveStatus(e, item)}
          />
        </ItemListItem>
      );
    });

    if (items.length === 0 && itemsLoaded) {
      if (statusView === 'valid') {
        allItems = (
          <div className="items-empty">
            <h1>
              {selectedTags.length === 0 && query.length === 0
                ? 'Your Reading List is Lonely'
                : 'Nothing with this filter 🤔'}
            </h1>

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
      } else {
        allItems = (
          <div className="items-empty">
            <h1>
              {selectedTags.length === 0 && query.length === 0
                ? 'Your Archive List is Lonely'
                : 'Nothing with this filter 🤔'}
            </h1>
          </div>
        );
      }
    }

    const snackBar = archiving ? (
      <div className="snackbar">
        {statusView === STATUS_VIEW_VALID ? 'Archiving...' : 'Unarchiving...'}
      </div>
    ) : (
      ''
    );
    return (
      <div className="home item-list">
        <div className="side-bar">
          <div className="widget filters">
            <input onKeyUp={this.handleTyping} placeHolder="search your list" />

            <ItemListTags
              availableTags={availableTags}
              selectedTags={selectedTags}
              onClick={this.toggleTag}
            />

            <div className="status-view-toggle">
              <a
                href={READING_LIST_ARCHIVE_PATH}
                onClick={e => this.toggleStatusView(e)}
                data-no-instant
              >
                {statusView === STATUS_VIEW_VALID
                  ? 'View Archive'
                  : 'View Reading List'}
              </a>
            </div>
          </div>
        </div>

        <div className="items-container">
          <div className={`results ${itemsLoaded ? 'results--loaded' : ''}`}>
            <div className="results-header">
              {statusView === STATUS_VIEW_VALID ? 'Reading List' : 'Archive'}
              {` (${totalCount > 0 ? totalCount : 'empty'})`}
            </div>
            <div>{allItems}</div>
          </div>

          <ItemListLoadMoreButton
            show={showLoadMoreButton}
            onClick={this.loadNextPage}
          />
        </div>

        {snackBar}
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
