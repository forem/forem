import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { FEED_ICONS } from '../packs/feedIcons.js.erb';

/* global userData sendHapticMessage showModal buttonFormData renderNewSidebarCount */

export class Feed extends Component {
  componentDidMount() {
    const { timeFrame } = this.props;
    const { reading_list_ids = [] } = userData(); // eslint-disable-line camelcase

    this.setState({ bookmarkedFeedItems: new Set(reading_list_ids) });

    Feed.getFeedItems(timeFrame).then(feedItems => {
      // Ensure first article is one with a main_image
      const featuredStory = feedItems.find(story => story.main_image !== null);
      // Remove that first one from the array.
      const index = feedItems.indexOf(featuredStory);
      feedItems.splice(index, 1);
      const subStories = feedItems;
      const organizedFeedItems = [featuredStory, subStories].flat();
      this.setState({
        feedItems: organizedFeedItems,
        podcastEpisodes: Feed.getPodcastEpisodes(),
      });
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

  static getPodcastEpisodes() {
    const el = document.getElementById('followed-podcasts');
    const user = userData(); // Global
    const episodes = [];
    if (
      user &&
      user.followed_podcast_ids &&
      user.followed_podcast_ids.length > 0
    ) {
      const data = JSON.parse(el.dataset.episodes);
      data.forEach(episode => {
        if (user.followed_podcast_ids.indexOf(episode.podcast.id) > -1) {
          episodes.push(episode);
        }
      });
    }
    return episodes;
  }

  /**
   * Dispatches a click event to bookmark/unbook,ard an article.
   *
   * @param {Event} event
   */
  bookmarkClick = event => {
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
            const articleId = Number(button.dataset.reactableId);

            this.setState(previousState => {
              const { bookmarkedFeedItems } = previousState;

              const { result } = json;
              const updatedBookmarkedFeedItems = new Set([
                ...bookmarkedFeedItems.values(),
              ]);

              if (result === 'create') {
                updatedBookmarkedFeedItems.add(articleId);
              }

              if (result === 'destroy') {
                updatedBookmarkedFeedItems.delete(articleId);
              }

              renderNewSidebarCount(button, json);

              return {
                ...previousState,
                bookmarkedFeedItems: updatedBookmarkedFeedItems,
              };
            });
          });
        }
      });
  };

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
          bookmarkClick: this.bookmarkClick,
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
};

Feed.displayName = 'Feed';
