import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { FEED_ICONS } from './feedIcons.js.erb';

/* global userData sendHapticMessage showModal buttonFormData renderNewSidebarCount */

export class Feed extends Component {
  componentDidMount() {
    const { timeFrame } = this.props;
    const { reading_list_ids = [] } = userData(); // eslint-disable-line camelcase

    this.setState({ bookmarkedFeedItems: new Set(reading_list_ids) });

    Feed.getFeedItems(timeFrame).then(feedItems => {
      this.setState({ feedItems });
    });
  }

  componentDidUpdate(prevProps) {
    const { timeFrame } = this.props;
    if (prevProps.timeFrame !== timeFrame) {
      // The feed timeframe has changed. Get new feed data.
      Feed.getFeedItems(timeFrame).then(feedItems => {
        this.setState(_prevState => ({ feedItems }));
      });
    }
  }

  /**
   * Retrieves feed data.
   *
   * @param {number} [page=1] Page of feed data to retrieve
   *
   * @returns {Promise} A promise containing the JSON response for the feed data.
   */
  static getFeedItems(timeFrame = '', page = 1) {
    return fetch(`/stories/feed/${timeFrame}?page=${page}`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    }).then(response => response.json());
  }

  /**
   * Dispatches a click event to bookmark/unbook,ard an article.
   *
   * @param {Event} event
   */
  bookmarkClick(event) {
    // The assumption is that the user is logged on at this point.
    const { userStatus } = document.body;
    event.preventDefault();
    sendHapticMessage('medium');

    if (userStatus === 'logged-out') {
      showModal('add-to-readinglist-from-index');
      return;
    }

    const { currentTarget: button } = event;
    const data = buttonFormData(button);

    getCsrfToken()
      .then(sendFetch('reaction-creation', data))
      // eslint-disable-next-line consistent-return
      .then(response => {
        if (response.status === 200) {
          return response.json().then(json => {
            renderNewSidebarCount(button, json);
          });
        }
      });
  }

  render() {
    const { renderFeed } = this.props;
    const {
      feedItems = [],
      podcastEpisodes = [],
      bookmarkedFeedItems = new Set(),
    } = this.state;

    return (
      <div
        ref={element => {
          this.feedContainer = element;
        }}
      >
        {renderFeed({
          feedItems,
          feedIcons: FEED_ICONS,
          podcastEpisodes,
          bookmarkedFeedItems,
        })}
      </div>
    );
  }
}

Feed.defaultProps = {
  timeFrame: '',
};

Feed.propTypes = {
  timeFrame: PropTypes.string,
  renderFeed: PropTypes.func.isRequired,
  bookmarkedFeedItems: PropTypes.instanceOf(Set).isRequired,
};

Feed.displayName = 'Feed';
