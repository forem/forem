import { h, render } from 'preact';
import PropTypes from 'prop-types';
import { Article, LoadingArticle } from '../articles';
import { Feed } from '../articles/Feed';
import { TodaysPodcasts, PodcastEpisode } from '../podcasts';
import { articlePropTypes } from '../common-prop-types';

/**
 * Sends analytics about the featured article.
 *
 * @param {number} articleId
 */
function sendFeaturedArticleAnalytics(articleId) {
  (function logFeaturedArticleImpression() {
    if (!window.ga || !ga.create) {
      setTimeout(logFeaturedArticleImpression, 20);
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

const FeedLoading = () => (
  <div>
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
export const renderFeed = (timeFrame) => {
  const feedContainer = document.getElementById('homepage-feed');

  render(
    <Feed
      timeFrame={timeFrame}
      renderFeed={({
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

        const [featuredStory, ...subStories] = feedItems;
        const feedStyle = JSON.parse(document.body.dataset.user).feed_style;
        if (featuredStory) {
          sendFeaturedArticleAnalytics(featuredStory.id);
        }

        // 1. Show the featured story first
        // 2. Podcast episodes out today
        // 3. Rest of the stories for the feed
        return (
          <div>
            {featuredStory && (
              <Article
                {...commonProps}
                article={featuredStory}
                isFeatured
                feedStyle={feedStyle}
                isBookmarked={bookmarkedFeedItems.has(featuredStory.id)}
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
