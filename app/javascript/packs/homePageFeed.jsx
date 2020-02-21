import { h, render } from 'preact';
import { Article, LoadingArticle } from '../articles';
import { FeaturedArticle } from '../articles/FeaturedArticle';
import { Feed } from './Feed.jsx.erb';

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

/**
 * Renders the main feed.
 */
export const renderFeed = timeFrame => {
  const feedContainer = document.getElementById('homepage-feed');

  // The feed is wrapped in a <div /> with the ID 'new-feed' so that current paging/scrolling
  // functionality does not affect the new feed.

  render(
    <Feed
      timeFrame={timeFrame}
      renderFeed={({ feedItems, feedIcons }) => {
        if (feedItems.length === 0) {
          // Fancy loading ✨
          return (
            <div id="new-feed">
              <LoadingArticle />
              <LoadingArticle />
              <LoadingArticle />
            </div>
          );
        }

        const [featuredStory, ...subStories] = feedItems;

        sendFeaturedArticleAnalytics(featuredStory.id);

        // 1. Show the featured story first
        // 2. Podcast episodes out today
        // 3. Rest of the stories for the feed
        return (
          <div id="new-feed">
            <FeaturedArticle
              article={featuredStory}
              reactionsIcon={feedIcons.REACTIONS_ICON}
              commentsIcon={feedIcons.COMMENTS_ICON}
            />
            <div id="article-index-podcast-div">PODCAST EPISODES</div>
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
