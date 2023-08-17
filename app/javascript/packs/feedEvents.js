const FeedEvents = {
  initialized: false,
};

/**
 * Sets up the feed events tracker.
 * Called every time posts are inserted into the feed.
 */
export function observeFeedElements() {
  const feedContainer = document.getElementById('index-container');
  if (!feedContainer) return;

  const { feedCategoryClick, feedCategoryImpression, feedContextType } =
    feedContainer.dataset;

  if (!FeedEvents.initialized) {
    FeedEvents.categoryClick = feedCategoryClick;
    FeedEvents.categoryImpression = feedCategoryImpression;
    FeedEvents.contextType = feedContextType;
    FeedEvents.observer ||= createImpressionsObserver();
    FeedEvents.initialized = true;
  } else {
    // Clear existing subscriptions, if any
    FeedEvents.observer.disconnect();
  }

  // Recalculating the positions of the entire feed whenever new stories are
  // loaded in is expensive, but something I can return to.
  // TODO: Maybe try out other ways to track last known position, or to make this
  // query more performant.
  // Note that currently, each new page of stories is rendered into the last page,
  // not into its parent element.
  let position = 1;
  feedContainer.querySelectorAll('[data-feed-content-id]').forEach((post) => {
    post.dataset.feedPosition = position;
    FeedEvents.observer.observe(post);
    post.addEventListener('click', trackFeedClickListener, true);

    position += 1;
  });
}

function createImpressionsObserver() {
  return new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      // At least a quarter of the card is in view; not quite enough to read the
      // title for many articles, but it'll do
      if (entry.isIntersecting && entry.intersectionRatio >= 0.25) {
        queueMicrotask(() => {
          trackFeedImpression(entry.target);
        });
      }
    });
  });
}

function trackFeedImpression(post) {
  const { impressionRecorded, feedContentId, feedPosition } = post.dataset;
  // TODO: Maybe don't swallow uninitialized FeedEvents.
  if (impressionRecorded || !FeedEvents.initialized) return;

  const impressionEvent = {
    article_id: feedContentId,
    article_position: feedPosition,
    context_type: FeedEvents.contextType,
    category: FeedEvents.categoryImpression,
  };

  submitRecord([impressionEvent]);

  post.dataset.impressionRecorded = true;
}

/**
 * Sends single click events to the server immediately.
 * These may not necessarily be clicks that open the article (e.g. the user may
 * have clicked on the author's profile image).
 * @param {MouseEvent} event
 */
function trackFeedClickListener(event) {
  const post = event.currentTarget;
  const { clickRecorded, feedContentId, feedPosition } = post.dataset;
  if (clickRecorded || !FeedEvents.initialized) return;

  const clickEvent = {
    article_id: feedContentId,
    article_position: feedPosition,
    context_type: FeedEvents.contextType,
    category: FeedEvents.categoryClick,
  };

  submitRecord([clickEvent]);

  post.dataset.clickRecorded = true;
}

/**
 * Sends a batch of feed events to
 * @param {[object]} events The list of events to be recorded
 */
function submitRecord(events) {
  if (events.length === 0) return;

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta?.getAttribute('content');
  const payload = {};
  if (events.length === 1) {
    payload.feed_event = events[0];
  } else {
    payload.feed_events = events;
  }

  window
    .fetch('/feed_events', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
      credentials: 'same-origin',
    })
    .catch((error) => console.error(error));
}
