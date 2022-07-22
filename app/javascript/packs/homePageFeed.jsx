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
export const renderFeed = async (timeFrame) => {
  const feedContainer = document.getElementById('homepage-feed');

  const { currentUser } = await getUserDataAndCsrfToken();
  const currentUserId = currentUser && currentUser.id;

  render(
    <Feed
      timeFrame={timeFrame}
      renderFeed={({
        pinnedArticle,
        feedItems,
        podcastEpisodes,
        bookmarkedFeedItems,
        bookmarkClick,
      }) => {
        if (feedItems.length === 0) {
          // Fancy loading ✨
          return <FeedLoading />;
        }

        const commonProps = {
          bookmarkClick,
        };

        const feedStyle = JSON.parse(document.body.dataset.user).feed_style;

        const [featuredStory, ...subStories] = feedItems;
        if (featuredStory) {
          sendFeaturedArticleGoogleAnalytics(featuredStory.id);
          sendFeaturedArticleAnalyticsGA4(featuredStory.id);
        }

        // 1. Show the pinned article first
        // 2. Show the featured story next
        // 3. Podcast episodes out today
        // 4. Rest of the stories for the feed
        // For "saveable", "!=" is used instead of "!==" to compare user_id
        // and currentUserId because currentUserId is a String while user_id is an Integer
        return (
          <div>
            {timeFrame === '' && pinnedArticle && (
              <Article
                {...commonProps}
                article={pinnedArticle}
                pinned={true}
                feedStyle={feedStyle}
                isBookmarked={bookmarkedFeedItems.has(pinnedArticle.id)}
                saveable={pinnedArticle.user_id != currentUserId}
              />
            )}
            {featuredStory && (
              <Article
                {...commonProps}
                article={featuredStory}
                isFeatured
                feedStyle={feedStyle}
                isBookmarked={bookmarkedFeedItems.has(featuredStory.id)}
                saveable={featuredStory.user_id != currentUserId}
              />
            )}
            {podcastEpisodes.length > 0 && (
              <PodcastEpisodes episodes={podcastEpisodes} />
            )}
            {(subStories || []).map((story) => (
              <Article
                {...commonProps}
                key={story.id}
                article={story}
                feedStyle={feedStyle}
                isBookmarked={bookmarkedFeedItems.has(story.id)}
                saveable={story.user_id != currentUserId}
              />
            ))}
          </div>
        );
      }}
    />,
    feedContainer,
    feedContainer.firstElementChild,
  );
};
