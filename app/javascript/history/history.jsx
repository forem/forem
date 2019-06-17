import { h, Component } from 'preact';
import setupAlgoliaIndex from '../src/utils/algolia';

export class History extends Component {
  state = {
    historyItems: [],
    totalCount: 0,
    index: null,
    itemsLoaded: false,
    hitsPerPage: 100,
  };

  componentDidMount() {
    const index = setupAlgoliaIndex({
      containerId: 'history',
      indexName: 'UserHistory',
    });

    // get default result set from Algolia
    const { hitsPerPage } = this.state;
    index.search('', { hitsPerPage }).then(content => {
      console.table(content);
      this.setState({
        historyItems: content.hits,
        totalCount: content.nbHits,
        index,
        itemsLoaded: true,
      });
    });

    // wait for user to be available
    const waitingOnUser = setInterval(() => {
      if (window.currentUser) {
        clearInterval(waitingOnUser);
      }
    }, 1);
  }

  handleTyping = e => {
    const query = e.target.value;
    this.search(query);
  };

  search(query) {
    const { index, hitsPerPage } = this.state;
    const filters = { hitsPerPage };

    index.search(query, filters).then(content => {
      this.setState({
        historyItems: content.hits,
        totalCount: content.nbHits,
      });
    });
  }

  render() {
    const { historyItems, itemsLoaded, totalCount } = this.state;

    let allItems = historyItems.map(item => (
      <div className="history-item-wrapper">
        <a className="history-item" href={item.article_path}>
          <div className="history-item-title">{item.article_title}</div>

          <div className="history-item-details">
            <a
              className="history-item-user"
              href={`/${item.article_user.username}`}
            >
              <img src={item.article_user.profile_image_90} alt="Profile Pic" />
              {item.article_user.name}・{item.created_at}
            </a>
          </div>

          <span className="history-item-tag-collection" />
        </a>
      </div>
    ));

    if (historyItems.length === 0 && itemsLoaded) {
      allItems = (
        <div className="history-empty">
          <h1>Your History is Lonely</h1>
        </div>
      );
    }

    return (
      <div className="home history-home">
        <div className="side-bar">
          <div className="widget history-filters">
            <input onKeyUp={this.handleTyping} placeHolder="search your list" />
            <div className="history-tags" />
          </div>
        </div>
        <div
          className={`history-results ${
            itemsLoaded ? 'history-results--loaded' : ''
          }`}
        >
          <div className="history-results-header">
            History {`(${totalCount})`}
          </div>
          <div>{allItems}</div>
        </div>
      </div>
    );
  }
}
