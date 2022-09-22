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
  const [pinnedArticle, setPinnedArticle] = useState(null);
  const [feedItems, setFeedItems] = useState([]);
  const [podcastEpisodes, setPodcastEpisodes] = useState([]);
  const [onError, setOnError] = useState(false);

  useEffect(() => {
    setPodcastEpisodes(getPodcastEpisodes());
  }, []);

  useEffect(() => {
    const fetchFeedItems = async () => {
      try {
        if (onError) setOnError(false);

        let feedItems = await getFeedItems(timeFrame);

        // Here we extract from the feed two special items: pinned and featured

        const pinnedArticle = feedItems.find((story) => story.pinned === true);

        // Ensure first article is one with a main_image
        // This is important because the featuredStory will
        // appear at the top of the feed, with a larger
        // main_image than any of the stories or feed elements.
        const featuredStory = feedItems.find(
          (story) => story.main_image !== null,
        );

        // If pinned and featured article aren't the same,
        // (either because featuredStory is missing or because they represent two different articles),
        // we set the pinnedArticle and remove it from feedItems.
        // If pinned and featured are the same, we just remove it from feedItems without setting it as state.
        // NB: We only show the pinned post on the "Relevant" feed (when there is no 'timeFrame' selected)
        if (pinnedArticle && timeFrame === '') {
          feedItems = feedItems.filter((item) => item.id !== pinnedArticle.id);

          if (pinnedArticle.id !== featuredStory?.id) {
            setPinnedArticle(pinnedArticle);
          }
        }

        // Remove that first story from the array to
        // prevent it from rendering twice in the feed.
        const featuredIndex = feedItems.indexOf(featuredStory);
        if (featuredStory) {
          feedItems.splice(featuredIndex, 1);
        }
        const organizedFeedItems = [featuredStory, feedItems].flat();

        setFeedItems(organizedFeedItems);
      } catch {
        if (!onError) setOnError(true);
      }
    };

    fetchFeedItems();
  }, [timeFrame, onError]);

  /**
   * Retrieves feed data.
   *
   * @param {number} [page=1] Page of feed data to retrieve
   *
   * @returns {Promise} A promise containing the JSON response for the feed data.
   */
  async function getFeedItems(timeFrame = '', page = 1) {
    const response = await fetch(`/stories/feed/${timeFrame}?page=${page}`, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    });
    return await response.json();
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
          pinnedArticle,
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
