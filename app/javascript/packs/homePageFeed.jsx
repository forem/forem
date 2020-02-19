import { h, render } from 'preact';
import { Article, Feed, LoadingArticle } from '../articles';

export const renderFeed = () => {
  const feedContainer = document.getElementById('homepage-feed');

  render(
    <Feed
      renderFeedItems={(feedItems = []) => {
        if (feedItems.length === 0) {
          // Fancy loading ✨
          return (
            <div>
              <LoadingArticle />
              <LoadingArticle />
              <LoadingArticle />
            </div>
          );
        }

        return (
          <div>
            <Article article={feedItems} />
            <div id="article-index-podcast-div">PODCAST EPISODES</div>

            {feedItems.slice(1).map(item => {
              const feedItem = item;

              return <Article article={feedItem} />;
            })}
          </div>
        );
      }}
    />,
    feedContainer,
    feedContainer.firstElementChild,
  );
};
