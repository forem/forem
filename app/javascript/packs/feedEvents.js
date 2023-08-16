export function observeFeedElements() {
  const feedContainer = document.getElementById('index-container');

  if (!feedContainer) return;

  const { feedCategoryClick, feedCategoryImpression, feedContextType } =
    feedContainer.dataset;
  const feedMeta = {
    articlePositions: {},
    categoryClick: feedCategoryClick,
    categoryImpression: feedCategoryImpression,
    contextType: feedContextType,
  };

  let position = 0;
  feedContainer.querySelectorAll('[data-feed-content-id]').forEach((post) => {
    feedMeta.articlePositions[post.dataset.feedContentId] = position;

    post.addEventListener('click', () => trackFeedClick(post, feedMeta));

    position += 1;
  });
}

function trackFeedClick(feedElement, feedMeta) {
  const clicked = feedElement.dataset.clickRecorded;
  if (clicked) return;

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta?.getAttribute('content');
  const id = feedElement.dataset.feedContentId;

  const clickEvent = {
    feed_event: {
      article_id: id,
      article_position: feedMeta.articlePositions[id],
      context_type: feedMeta.contextType,
      category: feedMeta.categoryClick,
    },
  };

  window
    .fetch('/feed_events', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(clickEvent),
      credentials: 'same-origin',
    })
    .catch((error) => console.error(error));

  feedElement.dataset.clickRecorded = true;
}
