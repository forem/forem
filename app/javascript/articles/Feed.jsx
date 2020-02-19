import { h, Component } from 'preact';
import PropTypes from 'prop-types';

// TODO: Add scroll initial fetch and scroll etc.
export class Feed extends Component {
  scrollHandler;

  componentDidMount() {
    this.scrollHandler = _event => {
      // // handle scroll logic for pages of feed data and get an extra page on load.
      // page += 1;
      // Feed.getFeedItems(page).then(feedItems => {
      //   // We are not doing virtual scrolling at the moment, so feed items keep getting appended.
      //   this.setState(previousState => ({
      //     feedItems: previousState.feedItems.concat(feedItems),
      //   }));
      // });
    };

    Feed.getFeedItems().then(feedItems => {
      this.setState({ feedItems });

      this.feedContainer.addEventListener('scroll', this.scrollHandler);
    });
  }

  componentWillUnmount() {
    if (this.scrollHandler) {
      this.feedContainer.removeEventListener('scroll', this.scrollHandler);
    }
  }

  /**
   * Retrieves feed data.
   *
   * @param {number} [page=1] Page of feed data to retrieve
   *
   * @returns {Promise} A promise containing the JSON response for the feed data.
   */
  static getFeedItems(page = 1) {
    return fetch(`/stories/feed?page=${page}`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    }).then(response => response.json());
  }

  render() {
    const { renderFeedItems } = this.props;
    const { feedItems } = this.state;

    return (
      <div
        ref={element => {
          this.feedContainer = element;
        }}
      >
        {renderFeedItems(feedItems)}
      </div>
    );
  }
}

Feed.propTypes = {
  renderFeedItems: PropTypes.func.isRequired,
};

Feed.displayName = 'Feed';
