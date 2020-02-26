import { h, render } from 'preact';
import { Article, LoadingArticle } from '../articles';
import { FeaturedArticle } from '../articles/FeaturedArticle';
import { Feed } from './Feed.jsx.erb';
import { PodcastFeed } from '../podcasts/PodcastFeed';

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
    <LoadingArticle version='featured' />
    <LoadingArticle />
    <LoadingArticle />
  </div>
);

/**
 * Renders the main feed.
 */
export const renderFeed = timeFrame => {
  const feedContainer = document.getElementById('homepage-feed');
  render(
    <Feed
      timeFrame={timeFrame}
      renderFeed={({ feedItems, podcastItems, feedIcons }) => {
        if (feedItems.length === 0) {
          // Fancy loading ✨
          return <FeedLoading />;
        }

        const [featuredStory, ...subStories] = feedItems;
        const podcastFeed = podcastItems.length > 0 ? <PodcastFeed podcastItems={podcastItems} /> : ''

        sendFeaturedArticleAnalytics(featuredStory.id);

        // 1. Show the featured story first
        // 2. Podcast episodes out today
        // 3. Rest of the stories for the feed
        return (
          <div>
            <FeaturedArticle
              article={featuredStory}
              reactionsIcon={feedIcons.REACTIONS_ICON}
              commentsIcon={feedIcons.COMMENTS_ICON}
            />
            {podcastFeed}
            {(subStories || []).map(story => (
              <Article
                article={story}
                reactionsIcon={feedIcons.REACTIONS_ICON}
                commentsIcon={feedIcons.COMMENTS_ICON}
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
