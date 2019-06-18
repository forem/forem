import { h, Component } from 'preact';
import { PropTypes } from 'preact-compat';
import setupAlgoliaIndex from '../src/utils/algolia';

export class History extends Component {
  constructor(props) {
    super(props);

    const { availableTags } = this.props;
    this.state = {
      query: '',
      items: [],
      totalCount: 0,
      index: null,
      itemsLoaded: false,
      hitsPerPage: 100,
      availableTags,
      selectedTags: [],
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
      });
    });
  }

  handleTyping = event => {
    const query = event.target.value;
    const { selectedTags } = this.state;

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

    this.setState({ selectedTags: newTags });
    this.search(query, { tags: newTags });
  };

  search(query, { tags }) {
    const { index, hitsPerPage } = this.state;
    const filters = { hitsPerPage };

    if (tags.length > 0) {
      filters.tagFilters = tags;
    }

    index.search(query, filters).then(content => {
      this.setState({
        query,
        items: content.hits,
        totalCount: content.nbHits,
      });
    });
  }

  render() {
    const {
      items,
      itemsLoaded,
      totalCount,
      availableTags,
      selectedTags,
      query,
    } = this.state;

    let allItems = items.map(item => (
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

    if (items.length === 0 && itemsLoaded) {
      allItems = (
        <div className="history-empty">
          <h1>
            {selectedTags.length === 0 && query.length === 0
              ? 'Your History is Lonely'
              : 'Nothing with this filter 🤔'}
          </h1>
        </div>
      );
    }

    const allTags = availableTags.map(tag => (
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
        </div>
      </div>
    );
  }
}

History.propTypes = {
  availableTags: PropTypes.arrayOf(PropTypes.string).isRequired,
};
