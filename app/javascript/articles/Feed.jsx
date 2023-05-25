import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { useListNavigation } from '../shared/components/useListNavigation';
import { useKeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';

/* global userData sendHapticMessage showLoginModal buttonFormData renderNewSidebarCount */

export const Feed = ({ timeFrame, renderFeed }) => {
  const { reading_list_ids = [] } = userData(); // eslint-disable-line camelcase
  const [bookmarkedFeedItems, setBookmarkedFeedItems] = useState(
    new Set(reading_list_ids),
  );
  const [pinnedItem, setPinnedItem] = useState(null);
  const [featuredItem, setFeaturedItem] = useState(null);
  const [feedItems, setFeedItems] = useState([]);
  const [podcastEpisodes, setPodcastEpisodes] = useState([]);
  const [onError, setOnError] = useState(false);

  useEffect(() => {
    const organizeFeedItems = async () => {
      try {
        if (onError) setOnError(false);

        fetchFeedItems(timeFrame).then(
          ([
            feedPosts,
            feedFirstBillboard,
            feedSecondBillboard,
            feedThirdBillboard,
          ]) => {
            // Ensure first article is one with a main_image
            // This is important because the featuredPost will
            // appear at the top of the feed, with a larger
            // main_image than any of the stories or feed elements.
            const featuredPost = feedPosts.find(
              (story) => story.main_image !== null,
            );

            // Remove that first story from the array to
            // prevent it from rendering twice in the feed.
            const featuredPostIndex = feedPosts.indexOf(featuredPost);
            if (featuredPost) {
              feedPosts.splice(featuredPostIndex, 1);
            }

            setFeaturedItem(featuredPost);

            // Here we extract from the feed two special items: pinned and featured
            const pinnedPost = feedPosts.find((story) => story.pinned === true);

            // We only show the pinned post on the "Relevant" feed (when there is no 'timeFrame' selected)
            if (pinnedPost && timeFrame === '') {
              // remove pinned article from the feed without setting it as state.
              feedPosts = feedPosts.filter((item) => item.id !== pinnedPost.id);

              // If pinned and featured article aren't the same,
              // (either because featuredPost is missing or because they represent two different articles),
              // we set the pinnedPost.
              if (pinnedPost.id !== featuredPost?.id) {
                // organizedFeedItems.push(pinnedPost);
                setPinnedItem(pinnedPost);
              }
            }

            const podcasts = getPodcastEpisodes();
            setPodcastEpisodes(podcasts);

            // 1. Show the pinned post first
            // 2. Show the featured post next
            // 3. Podcast episodes out today
            // 4. Rest of the stories for the feed
            // we filter by null in case there was not a pinned Article
            const organizedFeedItems = [
              pinnedPost,
              featuredPost,
              podcasts,
              feedPosts,
            ]
              .filter((item) => item !== null)
              .flat();

            organizedFeedItems.splice(0, 0, feedFirstBillboard);
            organizedFeedItems.splice(3, 0, feedSecondBillboard);
            organizedFeedItems.splice(9, 0, feedThirdBillboard);

            setFeedItems(organizedFeedItems);
          },
        );
      } catch {
        if (!onError) setOnError(true);
      }
    };
    organizeFeedItems();
  }, [timeFrame, onError]);

  // /**
  //  * Retrieves data for the feed. The data will include articles and billboards.
  //  *
  //  * @param {number} [page=1] Page of feed data to retrieve
  //  * @param {string} The time frame of feed data to retrieve
  //  *
  //  * @returns {Promise} A promise containing the JSON response for the feed data.
  //  */
  async function fetchFeedItems(timeFrame = '', page = 1) {
    const [
      feedPostsResponse,
      feedFirstBillboardResponse,
      feedSecondBillboardResponse,
      feedThirdBillboardResponse,
    ] = await Promise.all([
      fetch(`/stories/feed/${timeFrame}?page=${page}`, {
        method: 'GET',
        headers: {
          Accept: 'application/json',
          'X-CSRF-Token': window.csrfToken,
          'Content-Type': 'application/json',
        },
        credentials: 'same-origin',
      }),
      fetch(`/display_ads/feed_first`),
      fetch(`/display_ads/feed_second`),
      fetch(`/display_ads/feed_third`),
    ]);

    const feedPosts = await feedPostsResponse.json();
    const feedFirstBillboard = await feedFirstBillboardResponse.text();
    const feedSecondBillboard = await feedSecondBillboardResponse.text();
    const feedThirdBillboard = await feedThirdBillboardResponse.text();

    return [
      feedPosts,
      feedFirstBillboard,
      feedSecondBillboard,
      feedThirdBillboard,
    ];
  }

  function getPodcastEpisodes() {
    const el = document.getElementById('followed-podcasts');
    const user = userData(); // Global
    const episodes = [];
    if (
      user &&
      user.followed_podcast_ids &&
      user.followed_podcast_ids.length > 0
    ) {
      const data = JSON.parse(el.dataset.episodes);
      data.forEach((episode) => {
        if (user.followed_podcast_ids.indexOf(episode.podcast.id) > -1) {
          episodes.push(episode);
        }
      });
    }
    return episodes;
  }

  /**
   * Dispatches a click event to bookmark/unbookmark an article.
   *
   * @param {Event} event
   */
  async function bookmarkClick(event) {
    // The assumption is that the user is logged on at this point.
    const { userStatus } = document.body;
    event.preventDefault();
    sendHapticMessage('medium');

    if (userStatus === 'logged-out') {
      showLoginModal({
        referring_source: 'post_index_toolbar',
        trigger: 'readinglist',
      });
      return;
    }

    const { currentTarget: button } = event;
    const data = buttonFormData(button);

    const csrfToken = await getCsrfToken();
    if (!csrfToken) return;

    const fetchCallback = sendFetch('reaction-creation', data);
    const response = await fetchCallback(csrfToken);
    if (response.status === 200) {
      const json = await response.json();
      const articleId = Number(button.dataset.reactableId);

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

      setBookmarkedFeedItems(updatedBookmarkedFeedItems);
    }
  }

  useListNavigation(
    'article.crayons-story',
    'a.crayons-story__hidden-navigation-link',
    'div.paged-stories',
  );

  useKeyboardShortcuts({
    b: (event) => {
      const article = event.target?.closest('article.crayons-story');

      if (!article) return;

      article.querySelector('button[id^=article-save-button]')?.click();
    },
  });

  return (
    <div id="rendered-article-feed">
      {onError ? (
        <div class="crayons-notice crayons-notice--danger">
          There was a problem fetching your feed.
        </div>
      ) : (
        renderFeed({
          pinnedItem,
          featuredItem,
          feedItems,
          podcastEpisodes,
          bookmarkedFeedItems,
          bookmarkClick,
        })
      )}
    </div>
  );
};

Feed.defaultProps = {
  timeFrame: '',
};

Feed.propTypes = {
  timeFrame: PropTypes.string,
  renderFeed: PropTypes.func.isRequired,
};

Feed.displayName = 'Feed';
