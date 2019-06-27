import { h, Component } from 'preact';

export class ReadingList extends Component {
  state = {
    readingListItems: [],
    query: '',
    index: '',
    page: 0,
    totalReadingList: 0,
    availableTags: [],
    selectedTags: [],
    itemsLoaded: false,
    archiving: false,
    statusView: document.getElementById('reading-list').dataset.view,
    showLoadMoreButton: false,
  };

  componentDidMount() {
    const algoliaId = document.querySelector("meta[name='algolia-public-id']")
      .content;
    const algoliaKey = document.getElementById('reading-list').dataset.algolia;
    const env = document.querySelector("meta[name='environment']").content;
    const client = algoliasearch(algoliaId, algoliaKey);
    const index = client.initIndex(`SecuredReactions_${env}`);
    const t = this;
    index
      .search('', {
        page: t.state.page,
        hitsPerPage: 64,
        filters: `status:${t.state.statusView}`,
      })
      .then(content => {
        t.setState({
          totalReadingList: content.nbHits,
          readingListItems: content.hits,
          index,
          itemsLoaded: true,
        });
        this.shouldShowLoadMoreButton();
      });
    const waitingOnUser = setInterval(() => {
      if (window.currentUser) {
        t.setState({ availableTags: window.currentUser.followed_tag_names });
        clearInterval(waitingOnUser);
      }
    }, 1);
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
    this.setState({ selectedTags: newTags });
    this.listSearch(query, newTags, statusView);
  };

  toggleStatusView = e => {
    e.preventDefault();
    const { statusView, query, selectedTags } = this.state;
    if (statusView === 'valid') {
      this.setState({ statusView: 'archived' });
      this.listSearch(query, selectedTags, 'archived');
      window.history.replaceState(null, null, '/readinglist/archive');
    } else {
      this.setState({ statusView: 'valid' });
      this.listSearch(query, selectedTags, 'valid');
      window.history.replaceState(null, null, '/readinglist');
    }
  };

  archive = (e, item) => {
    e.preventDefault();
    const { statusView, readingListItems, totalReadingList } = this.state;
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
    const newItems = readingListItems;
    newItems.splice(newItems.indexOf(item), 1);
    t.setState({
      archiving: true,
      readingListItems: newItems,
      totalReadingList: totalReadingList - 1,
    });
    setTimeout(() => {
      t.setState({ archiving: false });
    }, 1800);
  };

  shouldShowLoadMoreButton = () => {
    const { totalReadingList, readingListItems } = this.state;
    const totalReadingListLoaded = readingListItems.length;
    this.setState({ showLoadMoreButton: true });
    if (totalReadingListLoaded >= totalReadingList) {
      this.setState({ showLoadMoreButton: false });
    }
  };

  loadNextReadingList = () => {
    const { statusView, query, selectedTags, page } = this.state;
    const isLoadMore = true;
    this.setState({ page: page + 1 });
    this.listSearch(query, selectedTags, statusView, isLoadMore);
  };

  listSearch(query, tags, statusView, isLoadMore = false) {
    const t = this;
    if (!isLoadMore) {
      this.setState({ page: 0 });
    }
    const { index, page, readingListItems } = this.state;
    const filters = { page, hitsPerPage: 64, filters: `status:${statusView}` };
    if (tags.length > 0) {
      filters.tagFilters = tags;
    }
    index.search(query, filters).then(content => {
      if (!isLoadMore) {
        t.setState({
          readingListItems: content.hits,
          totalReadingList: content.nbHits,
          query,
        });
      } else {
        t.setState({
          readingListItems: [...readingListItems, ...content.hits],
          totalReadingList: content.nbHits,
          query,
        });
      }
      this.shouldShowLoadMoreButton();
      t.setState({
        readingListItems: content.hits,
        totalReadingList: content.nbHits,
        query,
      });
    });
  }

  render() {
    const {
      archiving,
      availableTags,
      itemsLoaded,
      query,
      readingListItems,
      selectedTags,
      statusView,
      showLoadMoreButton,
      totalReadingList,
    } = this.state;
    let allItems = readingListItems.map(item => (
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
    if (readingListItems.length === 0 && itemsLoaded) {
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
    const allTags = availableTags.map(tag => (
      <a
        className={`readinglist-tag ${
          selectedTags.indexOf(tag) > -1 ? 'selected' : ''
        }`}
        href={`/t/${tag}`}
        data-no-instant
        onClick={e => this.toggleTag(e, tag)}
      >
        #
        {tag}
      </a>
    ));
    const snackBar = archiving ? (
      <div className="snackbar">
        {statusView === 'valid' ? 'Archiving' : 'Unarchiving'}
        (async)
      </div>
    ) : (
      ''
    );
    let loadMoreButton = '';
    if (showLoadMoreButton) {
      loadMoreButton = (
        <div className="classifieds-load-more-button">
          <button onClick={e => this.loadNextReadingList(e)} type="button">
            Load More Reading List
          </button>
        </div>
      );
    }
    return (
      <div className="home readinglist-home">
        <div className="side-bar">
          <div className="widget readinglist-filters">
            <input onKeyUp={this.handleTyping} placeHolder="search your list" />
            <div className="readinglist-tags">{allTags}</div>
            <div className="readinglist-view-toggle">
              <a
                href="/readinglist/archive"
                onClick={e => this.toggleStatusView(e)}
                data-no-instant
              >
                {statusView === 'valid' ? 'View Archive' : 'View Reading List'}
              </a>
            </div>
          </div>
        </div>
        <div className="readinglist-result-container">
          <div
            className={`readinglist-results ${
              itemsLoaded ? 'readinglist-results--loaded' : ''
            }`}
          >
            <div className="readinglist-results-header">
              {statusView === 'valid' ? 'Reading List' : 'Archive'}
              {` (${totalReadingList})`}
            </div>
            <div>{allItems}</div>
          </div>
          <div className="loadmore-wrapper">{loadMoreButton}</div>
        </div>
        {snackBar}
      </div>
    );
  }
}
