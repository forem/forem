const MAX_BATCH_SIZE = 20; // Maybe adjust?
const AUTOSEND_PERIOD = 5 * 1000;
const VISIBLE_THRESHOLD = 0.25;

const tracker = {
  queue: [],
  processInterval: null,
  observer: new IntersectionObserver(trackFeedImpressions, {
    root: null,
    rootMargin: '0px',
    threshold: VISIBLE_THRESHOLD,
  }),
  beaconEnabled: true,
  nextFeedPosition: null,
};
window.observeFeedElements = observeFeedElements;

/**
 * Sets up the feed events tracker.
 * Called every time posts are inserted into the feed.
 */
export function observeFeedElements() {
  const feedContainer = document.getElementById('index-container');
  // Default container for Preact-rendered home feed
  const feedItemsRoot = document.getElementById('rendered-article-feed');

  if (!(feedContainer && feedItemsRoot)) return;

  const { feedCategoryClick, feedCategoryImpression, feedContextType } =
    feedContainer.dataset;

  // Reset all relevant state
  tracker.categoryClick = feedCategoryClick;
  tracker.categoryImpression = feedCategoryImpression;
  tracker.contextType = feedContextType;
  tracker.processInterval ||= setInterval(submitEventsBatch, AUTOSEND_PERIOD);
  tracker.observer.disconnect();
  tracker.nextFeedPosition = 1;

  findAndTrackFeedItems(feedItemsRoot);
  ensureQueueIsClearedBeforeExit();
}

/**
 * Given how often it may be called, and the need to assign the correct positions
 * in the feed, we take a more efficient approach to finding feed items than
 * querying the entire DOM.
 * This manual recursion (and a good chunk of `useListNavigation.js` would be
 * unnecessary if `initScrolling.js` is updated to *not* create a waterfall of elements.
 * @param {HTMLElement} root The (current) element with feed items as children.
 */
function findAndTrackFeedItems(root) {
  Array.from(root.children).forEach((/** @type HTMLElement */ element) => {
    if (element.classList.contains('paged-stories')) {
      // This was inserted by `initScrolling, and will contain feed items within.
      findAndTrackFeedItems(element);
    } else if (element.dataset?.feedContentId) {
      element.dataset.feedPosition = tracker.nextFeedPosition;
      // Also captures right-click opens
      element.addEventListener('mousedown', trackFeedClickListener, true);
      tracker.observer.observe(element);

      tracker.nextFeedPosition += 1;
    }
  });
}

/**
 * Attempts to send any pending queued events before state is lost - e.g. when
 * navigating to a different page, or (on mobile) switching to a different app
 * (which can eventually cause the browser tab to be discarded in the background
 * at the operating system's discretion).
 * Both the unload event and the page visibility API are used as each one covers
 * some gaps that the other does not.
 */
function ensureQueueIsClearedBeforeExit() {
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState == 'hidden') submitEventsBatch();
  });
  window.addEventListener('beforeunload', submitEventsBatch);
}

/**
 * Collects feed impressions, counted as at least a quarter of the article card
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
          queueEvent(post, tracker.categoryImpression);
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
 * TODO: Only track link-opening clicks instead?
 * @param {MouseEvent} event
 */
function trackFeedClickListener(event) {
  const post = event.currentTarget;

  if (!post.dataset.clickRecorded) {
    queueEvent(post, tracker.categoryClick);
    post.dataset.clickRecorded = true;
    submitEventsBatch();
  }
}

function queueEvent(post, category) {
  const { feedContentId, feedPosition } = post.dataset;

  tracker.queue.push({
    article_id: feedContentId,
    article_position: feedPosition,
    category,
    context_type: tracker.contextType,
  });

  if (tracker.queue.length >= MAX_BATCH_SIZE) {
    submitEventsBatch();
  }
}

/**
 * Sends a batch of feed events to the server.
 * Note: requests made with `navigator.sendBeacon` have greater guarantees to
 * actually complete than regular fetch requests with the `keepalive` property
 * set. However, the former is a bit tedious to implement and is often
 * inadvertently blocked by users (e.g. via extensions like uBlock). So a fallback
 * to `fetch` is included to cover that.
 */
function submitEventsBatch() {
  if (tracker.queue.length === 0) return;

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const authenticity_token = tokenMeta?.getAttribute('content');

  if (tracker.beaconEnabled) {
    // The Beacon API doesn't actually let you set headers, so we set the content
    // type and CSRF token within the body itself (the browser will recognise the
    // former, and Rails will recognise the latter)
    const data = new Blob(
      [JSON.stringify({ authenticity_token, feed_events: tracker.queue })],
      { type: 'application/json' },
    );
    // `sendBeacon` returns true if sending a beacon worked, and false otherwise.
    tracker.beaconEnabled = navigator.sendBeacon('/feed_events', data);
  } else {
    fallbackRequest(authenticity_token);
  }

  tracker.queue = [];
}

function fallbackRequest(authenticity_token) {
  window
    .fetch('/feed_events', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': authenticity_token,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ feed_events: tracker.queue }),
      credentials: 'same-origin',
      keepalive: true,
    })
    .catch((error) => console.error(error));
}
