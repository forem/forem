import { h, render } from 'preact';
import { Article, LoadingArticle } from '../articles';
import { FeaturedArticle } from '../articles/FeaturedArticle';
import { Feed } from './Feed.jsx.erb';

/**
 * Renders the main feed.
 */
export const renderFeed = feedTimeFrame => {
  const feedContainer = document.getElementById('homepage-feed');

  // The feed is wrapped in a <div /> with the ID 'new-feed' so that current paging/scrolling
  // functionality does not affect the new feed.

  render(
    <Feed
      feedTimeFrame={feedTimeFrame}
      renderFeedItems={({ feedItems, feedIcons }) => {
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
