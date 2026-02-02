import { h, Fragment, render } from 'preact';
import PropTypes from 'prop-types';
import { Article, LoadingArticle } from '../articles';
import { Feed } from '../articles/Feed';
import { TodaysPodcasts, PodcastEpisode } from '../podcasts';
import { articlePropTypes } from '../common-prop-types';
import { createRootFragment } from '../shared/preact/preact-root-fragment';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';
import { NoResults } from '../shared/components/NoResults';

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
  const isRoot = document.body.dataset.isRootSubforem === 'true';

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
          isRoot={isRoot}
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
    isLoading,
  }) => {
    // Show loading state while fetching data
    if (isLoading) {
      return <FeedLoading />;
    }

    // Check if we have actual content (not just billboards)
    const hasActualContent = feedItems.some(item => 
      typeof item === 'object' && item.id && item.id !== 'dummy-story'
    );

    if (feedItems.length === 0 || !hasActualContent) {
      // Determine feed type from localStorage or URL
      const feedTypeOf = localStorage?.getItem('current_feed') || 'discover';
      const feedType = feedTypeOf === 'following' ? 'following' : 'discover';
      
      return (
        <NoResults 
          feedType={feedType}
        />
      );
    }

    return (
      <Fragment>
        {feedConstruct(
          pinnedItem,
          imageItem,
          feedItems,
          bookmarkedFeedItems,
          bookmarkClick,
          currentUserId,
        )}
      </Fragment>
    );
  };

  render(
    <Feed
      timeFrame={timeFrame}
      renderFeed={callback}
      afterRender={afterRender}
    />,
    createRootFragment(feedContainer, feedContainer.firstElementChild),
  );
};
