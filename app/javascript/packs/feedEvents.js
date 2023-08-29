const MAX_BATCH_SIZE = 20; // Maybe adjust?
const SECONDS = 1000;
const VISIBLE_THRESHOLD = 0.333;

const FeedEvents = {
  queue: [],
  processInterval: null,
  observer: new IntersectionObserver(trackFeedImpressions, {
    threshold: VISIBLE_THRESHOLD,
  }),
};

/**
 * Sets up the feed events tracker.
 * Called every time posts are inserted into the feed.
 */
export function observeFeedElements() {
  const feedContainer = document.getElementById('index-container');
  if (!feedContainer) {
    // TODO: Cleanup logic?
    return;
  }

  const { feedCategoryClick, feedCategoryImpression, feedContextType } =
    feedContainer.dataset;

  // Clear existing subscriptions, if any
  FeedEvents.observer.disconnect();

  FeedEvents.categoryClick = feedCategoryClick;
  FeedEvents.categoryImpression = feedCategoryImpression;
  FeedEvents.contextType = feedContextType;
  FeedEvents.processInterval ||= setInterval(submitEventsBatch, 10 * SECONDS);

  // Recalculating the positions of the entire feed whenever new stories are
  // loaded in is expensive, but something I can return to.
  // TODO: Maybe try out other ways to track last known position, or to make this
  // query more performant.
  // Note that currently, each new page of stories is rendered into the last page,
  // not into its parent element.
  let position = 1;
  feedContainer.querySelectorAll('[data-feed-content]').forEach((post) => {
    post.dataset.feedPosition = position;
    FeedEvents.observer.observe(post);
    post.addEventListener('click', trackFeedClickListener, true);

    position += 1;
  });
}

/**
 * Collects feed impressions, counted as at least a third of the article card
 * coming into view. This is typically enough to at least see the title and/or
 * a significant portion of the cover image.
 * @param {IntersectionObserverEntry[]} entries
 */
function trackFeedImpressions(entries) {
  entries.forEach((entry) => {
    // At least a quarter of the card is in view; not quite enough to read the
    // title for many articles, but it'll do
    if (entry.isIntersecting && entry.intersectionRatio >= VISIBLE_THRESHOLD) {
      queueMicrotask(() => {
        const post = entry.target;
        if (!post.dataset.impressionRecorded) {
          queueEvent(post, FeedEvents.categoryImpression);
          post.dataset.impressionRecorded = true;
        }
      });
    }
  });
}

/**
 * Sends click events to the server immediately along with any currently-batched
 * events.
 * These may not necessarily be clicks that open the article (e.g. the user may
 * have clicked on the author's profile image).
 * TODO: Possible follow-up to filter these out?
 * @param {MouseEvent} event
 */
function trackFeedClickListener(event) {
  const post = event.currentTarget;

  if (!post.dataset.clickRecorded) {
    queueEvent(post, FeedEvents.categoryClick);
    post.dataset.clickRecorded = true;
    submitEventsBatch();
  }
}

function queueEvent(post, category) {
  const { id, feedPosition } = post.dataset;

  FeedEvents.queue.push({
    article_id: id,
    article_position: feedPosition,
    category,
    context_type: FeedEvents.contextType,
  });

  if (FeedEvents.queue.length >= MAX_BATCH_SIZE) {
    submitEventsBatch();
  }
}

/**
 * Sends a batch of feed events to the server.
 * There is a possibility that a batch will be dropped/lost due to closing the
 * tab etc, but that is mostly noise.
 */
function submitEventsBatch() {
  if (FeedEvents.queue.length === 0) return;

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta?.getAttribute('content');

  window
    .fetch('/feed_events', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ feed_events: FeedEvents.queue }),
      credentials: 'same-origin',
    })
    .catch((error) => console.error(error));

  FeedEvents.queue = [];
}
