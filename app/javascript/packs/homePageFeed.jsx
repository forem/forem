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
            {feedItems.map(item => {
              const feedItem = item;
              // BEGIN: Remove this mapping once server-side changes have been made.
              if (feedItem.cached_user) {
                feedItem.user = feedItem.cached_user.table;
              }

              if (feedItem.cached_organization) {
                feedItem.organization = feedItem.cached_organization.table;
              }
              // END: Remove this mapping once server-side changes have been made.

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

renderFeed();
