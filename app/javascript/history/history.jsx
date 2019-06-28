import { h, Component } from 'preact';
import { PropTypes } from 'preact-compat';
import debounce from 'lodash.debounce';
import setupAlgoliaIndex from '../src/utils/algolia';

export class History extends Component {
  constructor(props) {
    super(props);

    this.handleTyping = debounce(this.handleTyping.bind(this), 300, {
      leading: true,
    });

    const { availableTags } = this.props;
    this.state = {
      query: '',
      index: null,

      page: 0,
      hitsPerPage: 100,
      totalCount: 0,

      items: [],
      itemsLoaded: false,

      availableTags,
      selectedTags: [],

      showLoadMoreButton: false,
    };
  }

  componentDidMount() {
    const index = setupAlgoliaIndex({
      containerId: 'history',
      indexName: 'UserHistory',
    });

    // get default result set from Algolia
    const { hitsPerPage } = this.state;
    index.search('', { hitsPerPage }).then(content => {
      this.setState({
        items: content.hits,
        totalCount: content.nbHits,
        index,
        itemsLoaded: true,
        showLoadMoreButton: content.hits.length === hitsPerPage,
      });
    });
  }

  handleTyping = event => {
    const query = event.target.value;
    const { selectedTags } = this.state;

    this.setState({ page: 0, items: [] });
    this.search(query, { tags: selectedTags });
  };

  toggleTag = (event, tag) => {
    event.preventDefault();

    const { query, selectedTags } = this.state;
    const newTags = selectedTags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag);
    } else {
      newTags.splice(newTags.indexOf(tag), 1);
    }

    this.setState({ selectedTags: newTags, page: 0, items: [] });
    this.search(query, { tags: newTags });
  };

  loadNextPage = () => {
    const { query, selectedTags, page } = this.state;
    this.setState({ page: page + 1 });
    this.search(query, { selectedTags });
  };

  search(query, { tags }) {
    const { index, hitsPerPage, page, items } = this.state;
    const filters = { hitsPerPage, page };

    if (tags && tags.length > 0) {
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

  renderNoItems() {
    const { selectedTags, query } = this.state;

    return (
      <div className="history-empty">
        <h1>
          {selectedTags.length === 0 && query.length === 0
            ? 'Your History is Lonely'
            : 'Nothing with this filter 🤔'}
        </h1>
      </div>
    );
  }

  renderItems() {
    const { items, itemsLoaded } = this.state;

    if (items.length === 0 && itemsLoaded) {
      return this.renderNoItems();
    }

    return items.map(item => (
      <div className="history-item-wrapper">
        <a className="history-item" href={item.article_path}>
          <div className="history-item-title">{item.article_title}</div>

          <div className="history-item-details">
            <a
              className="history-item-user"
              href={`/${item.article_user.username}`}
            >
              <img src={item.article_user.profile_image_90} alt="Profile Pic" />
              {item.article_user.name}
・
              {item.article_reading_time}
              {' '}
min read・
              {`visited on ${item.readable_visited_at}`}
・
            </a>
            <span className="history-item-tag-collection">
              {item.article_tags.map(tag => (
                <a className="history-item-tag" href={`/t/${tag}`}>
                  #
                  {tag}
                </a>
              ))}
            </span>
          </div>
        </a>
      </div>
    ));
  }

  renderTags() {
    const { availableTags, selectedTags } = this.state;

    return availableTags.map(tag => (
      <a
        className={`history-tag ${
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
  }

  renderNextPageButton() {
    const { showLoadMoreButton } = this.state;

    if (showLoadMoreButton) {
      return (
        <div className="history-results-load-more">
          <button onClick={e => this.loadNextPage(e)} type="button">
            Load More
          </button>
        </div>
      );
    }
    return '';
  }

  render() {
    const { itemsLoaded, totalCount } = this.state;

    const allItems = this.renderItems();
    const allTags = this.renderTags();
    const nextPageButton = this.renderNextPageButton();

    return (
      <div className="home history-home">
        <div className="side-bar">
          <div className="widget history-filters">
            <input onKeyUp={this.handleTyping} placeHolder="search your list" />
            <div className="history-tags">{allTags}</div>
          </div>
        </div>
        <div
          className={`history-results ${
            itemsLoaded ? 'history-results--loaded' : ''
          }`}
        >
          <div className="history-results-header">
            History 
            {' '}
            {`(${totalCount})`}
          </div>
          <div>{allItems}</div>
          {nextPageButton}
        </div>
      </div>
    );
  }
}

History.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
};
