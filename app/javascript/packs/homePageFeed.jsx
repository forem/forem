import { h, render } from 'preact';
import PropTypes from 'prop-types';
import { Article, LoadingArticle } from '../articles';
import { Feed } from '../articles/Feed';
import { TodaysPodcasts, PodcastEpisode } from '../podcasts';
import { articlePropTypes } from '../common-prop-types';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

/**
 * Sends analytics about the featured article.
 *
 * @param {number} articleId
 */
function sendFeaturedArticleGoogleAnalytics(articleId) {
  (function logFeaturedArticleImpressionGA() {
    if (!window.ga || !ga.create) {
      setTimeout(logFeaturedArticleImpressionGA, 20);
      return;
    }

    ga(
      'send',
      'event',
      'view',
      'featured-feed-impression',
      `articles-${articleId}`,
      null,
    );
  })();
}

function sendFeaturedArticleAnalyticsGA4(articleId) {
  (function logFeaturedArticleImpressionGA4() {
    if (!window.gtag) {
      setTimeout(logFeaturedArticleImpressionGA4, 20);
      return;
    }

    gtag('event', 'featured-feed-impression', {
      event_category: 'view',
      event_label: `articles-${articleId}`,
    });
  })();
}

function feedConstruct(
  pinnedItem,
  imageItem,
  feedItems,
  bookmarkedFeedItems,
  bookmarkClick,
  currentUserId,
) {
  const commonProps = {
    bookmarkClick,
  };

  const feedStyle = JSON.parse(document.body.dataset.user).feed_style;

  if (imageItem) {
    sendFeaturedArticleGoogleAnalytics(imageItem.id);
    sendFeaturedArticleAnalyticsGA4(imageItem.id);
  }

  return feedItems.map((item) => {
    // billboard is an html string
    if (typeof item === 'string') {
      return (
        <div
          key={item.id}
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{
            __html: item,
          }}
        />
      );
    }

    if (Array.isArray(item) && item[0].podcast) {
      return <PodcastEpisodes key={item.id} episodes={item} />;
    }

    if (typeof item === 'object') {
      return (
        <Article
          {...commonProps}
          key={item.id}
          article={item}
          pinned={item.id === pinnedItem?.id}
          isFeatured={item.id === imageItem?.id}
          feedStyle={feedStyle}
          isBookmarked={bookmarkedFeedItems.has(item.id)}
          saveable={item.user_id != currentUserId}
          // For "saveable" props, "!=" is used instead of "!==" to compare user_id
          // and currentUserId because currentUserId is a String while user_id is an Integer
        />
      );
    }
  });
}

const FeedLoading = () => (
  <div data-testid="feed-loading">
    <LoadingArticle version="featured" />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
    <LoadingArticle />
  </div>
);

const PodcastEpisodes = ({ episodes }) => (
  <TodaysPodcasts>
    {episodes.map((episode) => (
      <PodcastEpisode episode={episode} key={episode.podcast.id} />
    ))}
  </TodaysPodcasts>
);

PodcastEpisodes.defaultProps = {
  episodes: [],
};

PodcastEpisodes.propTypes = {
  episodes: PropTypes.arrayOf(articlePropTypes),
};

/**
 * Renders the main feed.
 */
export const renderFeed = async (timeFrame, afterRender) => {
  const feedContainer = document.getElementById('homepage-feed');

  const { currentUser } = await getUserDataAndCsrfToken();
  const currentUserId = currentUser && currentUser.id;

  const callback = ({
    pinnedItem,
    imageItem,
    feedItems,
    bookmarkedFeedItems,
    bookmarkClick,
  }) => {
    if (feedItems.length === 0) {
      // Fancy loading ✨
      return <FeedLoading />;
    }

    return (
      <div>
        {feedConstruct(
          pinnedItem,
          imageItem,
          feedItems,
          bookmarkedFeedItems,
          bookmarkClick,
          currentUserId,
        )}
      </div>
    );
  };

  render(
    <Feed
      timeFrame={timeFrame}
      renderFeed={callback}
      afterRender={afterRender}
    />,
    feedContainer,
    feedContainer.firstElementChild,
  );
};
