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
  const [imageItem, setimageItem] = useState(null);
  const [feedItems, setFeedItems] = useState([]);
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
            const organizedFeedItems = [];
            // Ensure first article is one with a main_image
            // This is important because the imagePost will
            // appear at the top of the feed, with a larger
            // main_image than any of the stories or feed elements.
            const imagePost = feedPosts.find(
              (post) => post.main_image !== null,
            );

            // Here we extract from the feed two special items: pinned and image
            const pinnedPost = feedPosts.find((post) => post.pinned === true);

            // We only show the pinned post on the "Relevant" feed (when there is no 'timeFrame' selected)
            if (pinnedPost && timeFrame === '') {
              // remove pinned article from the feed without setting it as state.
              feedPosts = feedPosts.filter((item) => item.id !== pinnedPost.id);

              // If the pinned and the image post aren't the same,
              // (either because imagePost is missing or because they represent two different posts),
              // we set the pinnedPost.
              if (pinnedPost.id !== imagePost?.id) {
                setPinnedItem(pinnedPost);
                organizedFeedItems.push(pinnedPost);
              }
            }

            // Remove that first post from the array to
            // prevent it from rendering twice in the feed.
            const imagePostIndex = feedPosts.indexOf(imagePost);
            if (imagePost) {
              feedPosts.splice(imagePostIndex, 1);
              setimageItem(imagePost);
              organizedFeedItems.push(imagePost);
            }

            const podcasts = getPodcastEpisodes();

            if (podcasts.length > 0) {
              organizedFeedItems.push(podcasts);
            }
            // we want to expand the array into the organizedFeedItems
            organizedFeedItems.push(...feedPosts);

            // 1. Show the pinned post first
            // 2. Show the image post next
            // 3. Podcast episodes out today as an array
            // 4. Rest of the stories for the feed
            // we filter by null in case there was not a pinned Article

            if (organizedFeedItems.length >= 0 && feedFirstBillboard) {
              organizedFeedItems.splice(0, 0, feedFirstBillboard);
            }

            if (organizedFeedItems.length >= 3 && feedSecondBillboard) {
              organizedFeedItems.splice(3, 0, feedSecondBillboard);
            }

            if (organizedFeedItems.length >= 9 && feedThirdBillboard) {
              organizedFeedItems.splice(9, 0, feedThirdBillboard);
            }
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
          imageItem,
          feedItems,
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
