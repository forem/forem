import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { useListNavigation } from '../shared/components/useListNavigation';
import { useKeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { insertInArrayIf } from '../../javascript/utilities/insertInArrayIf';
import { initializeDropdown } from '@utilities/dropdownUtils';

/* global userData sendHapticMessage showLoginModal buttonFormData renderNewSidebarCount */

export const Feed = ({ timeFrame, renderFeed, afterRender }) => {
  const { reading_list_ids = [] } = userData(); // eslint-disable-line camelcase
  const [bookmarkedFeedItems, setBookmarkedFeedItems] = useState(
    new Set(reading_list_ids),
  );
  const [pinnedItem, setPinnedItem] = useState(null);
  const [imageItem, setimageItem] = useState(null);
  const [feedItems, setFeedItems] = useState([]);
  const [onError, setOnError] = useState(false);

  useEffect(() => {
    // /**
    //  * Retrieves data for the feed. The data will include articles and billboards.
    //  *
    //  * @param {number} [page=1] Page of feed data to retrieve
    //  * @param {string} The time frame of feed data to retrieve
    //  *
    //  * @returns {Promise} A promise containing the JSON response for the feed data.
    //  */
    async function fetchFeedItems(timeFrame = '', page = 1) {
      const feedTypeOf = localStorage?.getItem('current_feed') || 'discover';
      const promises = [
        fetch(`/stories/feed/${timeFrame}?page=${page}&type_of=${feedTypeOf}`, {
          method: 'GET',
          headers: {
            Accept: 'application/json',
            'X-CSRF-Token': window.csrfToken,
            'Content-Type': 'application/json',
          },
          credentials: 'same-origin',
        }),
        fetch(`/billboards/feed_first`),
        fetch(`/billboards/feed_second`),
        fetch(`/billboards/feed_third`),
      ];

      const results = await Promise.allSettled(promises);
      const feedItems = [];
      for (const result of results) {
        if (result.status === 'fulfilled') {
          let resolvedValue;
          if (isJSON(result)) {
            resolvedValue = await result.value.json();
          }

          if (isHTML(result)) {
            resolvedValue = await result.value.text();
          }
          feedItems.push(resolvedValue);
        } else {
          Honeybadger.notify(
            `failed to fetch some items on the home feed: ${result.reason}`,
          );
          // we push an undefined item because we want to maintain the placement of the deconstructed array.
          // it gets removed before display when we further organize.
          feedItems.push(undefined);
        }
      }
      return feedItems;
    }

    // /**
    //  * Sets the Pinned Item into state.
    //  *
    //  * @param {Object} The pinnedPost
    //  * @param {Object} The imagePost
    //  *
    //  * @returns {boolean} If we set the pinned post we return true else we return false
    //  */
    function setPinnedPostItem(pinnedPost, imagePost) {
      // We only show the pinned post on the "Relevant" feed (when there is no 'timeFrame' selected)
      if (!pinnedPost || timeFrame !== '') return false;

      // If the pinned and the image post aren't the same, (either because imagePost is missing or
      // because they represent two different posts), we set the pinnedPost
      if (pinnedPost.id !== imagePost?.id) {
        setPinnedItem(pinnedPost);
        return true;
      }

      return false;
    }

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
            const imagePost = getImagePost(feedPosts);
            const pinnedPost = getPinnedPost(feedPosts);
            const podcastPost = getPodcastEpisodes();

            const hasSetPinnedPost = setPinnedPostItem(pinnedPost, imagePost);
            const hasSetImagePostItem = setImagePostItem(imagePost);

            const updatedFeedPosts = updateFeedPosts(
              feedPosts,
              imagePost,
              pinnedPost,
            );

            // We implement the following organization for the feed:
            // 1. Place the pinned post first (if the timeframe is relevant)
            // 2. Place the image post next
            // 3. If you follow podcasts, place the podcast episodes that are
            // published today (this is an array)
            // 4. Place the rest of the stories for the feed
            // 5. Insert the billboards in that array accordingly
            // - feed_first: Before all home page posts
            // - feed_second: Between 2nd and 3rd posts in the feed
            // - feed_third: Between 7th and 8th posts in the feed

            const organizedFeedItems = [
              ...insertInArrayIf(hasSetPinnedPost, pinnedPost),
              ...insertInArrayIf(hasSetImagePostItem, imagePost),
              ...insertInArrayIf(podcastPost.length > 0, podcastPost),
              ...updatedFeedPosts,
            ];

            const organizedFeedItemsWithBillboards = insertBillboardsInFeed(
              organizedFeedItems,
              feedFirstBillboard,
              feedSecondBillboard,
              feedThirdBillboard,
            );

            setFeedItems(organizedFeedItemsWithBillboards);
          },
        );
      } catch {
        if (!onError) setOnError(true);
      }
    };
    organizeFeedItems();
  }, [timeFrame, onError]);

  useEffect(() => {
    if (feedItems.length > 0) {
      afterRender();
    }
  }, [afterRender, feedItems.length]);

  // /**
  //  * Retrieves the imagePost which will later appear at the top of the feed,
  //  * with a larger main_image than any of the stories or feed elements.
  //  *
  //  * @param {Array} The original feed posts that are retrieved from the endpoint.
  //  *
  //  * @returns {Object} The first post with a main_image
  //  */
  function getImagePost(feedPosts) {
    return feedPosts.find((post) => post.main_image !== null);
  }

  // /**
  //  * Retrieves the pinnedPost which will later appear at the top the feed with a pin.
  //  *
  //  * @param {Array} The original feed posts that are retrieved from the endpoint.
  //  *
  //  * @returns {Object} The first post that has pinned set to true
  //  */
  function getPinnedPost(feedPosts) {
    return feedPosts.find((post) => post.pinned === true);
  }

  // /**
  //  * Sets the Image Item into state.
  //  *
  //  * @param {Object} The imagePost
  //  *
  //  * @returns {boolean} If we set the pinned post we return true
  //  */
  function setImagePostItem(imagePost) {
    if (imagePost) {
      setimageItem(imagePost);
      return true;
    }
  }

  // /**
  //  * Updates the feedPosts to remove the relevant items like the pinned
  //  * post and the image post that will be added to the top of final organized feed
  //  * items separately. We do not want duplication.
  //  *
  //  * @param {Array} The original feed posts that are retrieved from the endpoint.
  //  * @param {Object} The imagePost
  //  * @param {Object} The pinnedPost
  //  *
  //  * @returns {Array} We return the new array that no longer contains the pinned post or the image post.
  //  */
  function updateFeedPosts(feedPosts, imagePost, pinnedPost) {
    let filteredFeedPost = feedPosts;
    if (pinnedPost) {
      filteredFeedPost = feedPosts.filter((item) => item.id !== pinnedPost.id);
    }

    if (imagePost) {
      const imagePostIndex = filteredFeedPost.indexOf(imagePost);
      filteredFeedPost.splice(imagePostIndex, 1);
    }

    return filteredFeedPost;
  }

  // /**
  //  * Inserts the billboards (if they exist) into the feed.
  //  *
  //  * @param {organizedFeedItems} The partially organized feed items.
  //  * @param {String} feedFirstBillboard is the feed_first billboard retrieved from an endpoint.
  //  * @param {String} feedSecondBillboard is the feed_second billboard retrieved from an endpoint.
  //  * @param {String} feedThirdBillboard is the feed_third billboard retrieved from an endpoint.
  //  *
  //  * @returns {Array} We return the array containing the billboards slotted into the correct positions.
  //  */
  function insertBillboardsInFeed(
    organizedFeedItems,
    feedFirstBillboard,
    feedSecondBillboard,
    feedThirdBillboard,
  ) {
    if (
      organizedFeedItems.length >= 9 &&
      feedThirdBillboard &&
      !isDismissed(feedThirdBillboard)
    ) {
      organizedFeedItems.splice(7, 0, feedThirdBillboard);
    }

    if (
      organizedFeedItems.length >= 3 &&
      feedSecondBillboard &&
      !isDismissed(feedSecondBillboard)
    ) {
      organizedFeedItems.splice(2, 0, feedSecondBillboard);
    }

    if (
      organizedFeedItems.length >= 0 &&
      feedFirstBillboard &&
      !isDismissed(feedFirstBillboard)
    ) {
      organizedFeedItems.splice(0, 0, feedFirstBillboard);
    }

    return organizedFeedItems;
  }

  function isJSON(result) {
    return result.value.headers
      ?.get('content-type')
      ?.includes('application/json');
  }

  function isHTML(result) {
    return result.value.headers?.get('content-type')?.includes('text/html');
  }

  function isDismissed(bb) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(bb, 'text/html');
    const element = doc.querySelector('.crayons-story');
    const dismissalSku = element?.dataset?.dismissalSku;
    if (localStorage && dismissalSku && dismissalSku.length > 0) {
      const skuArray =
        JSON.parse(localStorage.getItem('dismissal_skus_triggered')) || [];
      if (skuArray.includes(dismissalSku)) {
        return true;
      }
    } else {
      return false;
    }
  }

  // /**
  //  * Retrieves the podcasts for the feed from the user data and the `followed-podcasts`
  //  * div item.
  //  *
  //  * @returns {Object} An Object containing today's podcast episodes for the podcasts found in followed_podcast_ids.
  //  */
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
   * Dispatches a click event to bookmark/unbookmark an article and sets the ID's of the
   * updated bookmark feed items.
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

function initializeMainStatusForm() {

  initializeDropdown({
    triggerElementId: 'feed-dropdown-trigger',
    dropdownContentId: 'feed-dropdown-menu',
  });  

  let lastClickedElement = null;
  document.addEventListener("mousedown", (event) => {
    lastClickedElement = event.target;
  });
  const mainForm = document.getElementById('main-status-form');
  if (!mainForm) {
    return;
  }

  const waitingForCSRF = setInterval(() => {
    if (window.csrfToken !== undefined) {
      mainForm.querySelector('input[name="authenticity_token"]').value = window.csrfToken;
      clearInterval(waitingForCSRF);
    }
  }, 25);

  document.getElementById('article_title').onfocus = function (e) {
    const textarea = e.target;
    textarea.classList.add('element-focused')
    document.getElementById('main-status-form-controls').classList.add('flex');
    document.getElementById('main-status-form-controls').classList.remove('hidden');
    textarea.style.height = `${textarea.scrollHeight + 3}px`; // Set height to content height
    
  }
  document.getElementById('article_title').onblur = function (e) {
    if (mainForm.contains(lastClickedElement)) {
      e.preventDefault();
      e.target.focus();
    }
    else {
      e.target.classList.remove('element-focused')
      document.getElementById('main-status-form-controls').classList.remove('flex');
      document.getElementById('main-status-form-controls').classList.add('hidden');
    }
  }
  // Prevent return element from creating linebreak

}

Feed.defaultProps = {
  timeFrame: '',
};

Feed.propTypes = {
  timeFrame: PropTypes.string,
  renderFeed: PropTypes.func.isRequired,
};

Feed.displayName = 'Feed';

if (window && window.InstantClick) {
  window.InstantClick.on('change', () => {
    initializeMainStatusForm();
  });
}

initializeMainStatusForm();
