import { h, Component } from 'preact';
import { PropTypes } from 'preact-compat';
import debounce from 'lodash.debounce';
import setupAlgoliaIndex from '../src/utils/algolia';

import { ItemListLoadMoreButton } from '../src/components/ItemList/ItemListLoadMoreButton';
import { ItemListTags } from '../src/components/ItemList/ItemListTags';

const STATUS_VIEW_VALID = 'valid';
const STATUS_VIEW_ARCHIVED = 'archived';

export class ReadingList extends Component {
  constructor(props) {
    super(props);

    this.handleTyping = debounce(this.handleTyping.bind(this), 300, {
      leading: true,
    });

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
      window.history.replaceState(null, null, '/readinglist/archive');
    } else {
      this.setState({ statusView: STATUS_VIEW_VALID, page: 0, items: [] });
      this.listSearch(query, selectedTags, STATUS_VIEW_VALID);
      window.history.replaceState(null, null, '/readinglist');
    }
  };

  archive = (e, item) => {
    e.preventDefault();
    const { statusView, items, totalCount } = this.state;
    const t = this;
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
    t.setState({
      archiving: true,
      items: newItems,
      totalCount: totalCount - 1,
    });
    setTimeout(() => {
      t.setState({ archiving: false });
    }, 1800);
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
    let allItems = items.map(item => (
      <div className="readinglist-item-wrapper">
        <a className="readinglist-item" href={item.searchable_reactable_path}>
          <div className="readinglist-item-title">
            {item.searchable_reactable_title}
          </div>
          <div className="readinglist-item-details">
            <a
              className="readinglist-item-user"
              href={`/${item.reactable_user.username}`}
            >
              <img
                src={item.reactable_user.profile_image_90}
                alt="Profile Pic"
              />
              {item.reactable_user.name}
・
              {item.reactable_published_date}
・
              {item.reading_time}
              {' '}
min read・
            </a>
            <span className="readinglist-item-tag-collection">
              {item.reactable_tags.map(tag => (
                <a className="readinglist-item-tag" href={`/t/${tag}`}>
                  #
                  {tag}
                </a>
              ))}
            </span>
          </div>
        </a>
        <button
          className="readinglist-archive-butt"
          onClick={e => this.archive(e, item)}
          type="button"
        >
          {statusView === 'valid' ? 'archive' : 'unarchive'}
        </button>
      </div>
    ));
    if (items.length === 0 && itemsLoaded) {
      if (statusView === 'valid') {
        allItems = (
          <div className="readinglist-empty">
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
          <div className="readinglist-empty">
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
        {statusView === STATUS_VIEW_VALID ? 'Archiving' : 'Unarchiving'}
        (async)
      </div>
    ) : (
      ''
    );

    return (
      <div className="home readinglist-home">
        <div className="side-bar">
          <div className="widget readinglist-filters">
            <input onKeyUp={this.handleTyping} placeHolder="search your list" />
            <ItemListTags
              availableTags={availableTags}
              selectedTags={selectedTags}
              onClick={this.toggleTag}
            />
            <div className="readinglist-view-toggle">
              <a
                href="/readinglist/archive"
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
          <div
            className={`readinglist-results ${
              itemsLoaded ? 'readinglist-results--loaded' : ''
            }`}
          >
            <div className="readinglist-results-header">
              {statusView === STATUS_VIEW_VALID ? 'Reading List' : 'Archive'}
              {` (${totalReadingList > 0 ? totalReadingList : 'empty'})`}
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
