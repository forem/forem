const MAX_BATCH_SIZE = 20;
const AUTOSEND_PERIOD = 5 * 1000;
const VISIBLE_THRESHOLD = 0.25;
const REQUEST_TIMEOUT = 10 * 1000;
const MAX_QUEUE_SIZE = 200;
const MAX_ATTEMPTS = 6;
const MAX_RETRY_DELAY = 5 * 60 * 1000;

function createEventId() {
  const { crypto } = window;
  if (crypto.randomUUID) return crypto.randomUUID();

  const bytes = crypto.getRandomValues(new Uint8Array(16));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  const hex = Array.from(bytes, (byte) =>
    byte.toString(16).padStart(2, '0'),
  ).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/**
 * A class to track view and click events for items in a feed.
 * Each instance of this class manages its own event queue and configuration,
 * allowing for multiple independent feeds to be tracked on the same page.
 *
 * NOTE: this module has E2E tests at `seededFlows/homeFeedFlows/events.spec.js`
 */
export class FeedTracker {
  /**
   * @param {object} options - The configuration for this tracker instance.
   * @param {HTMLElement} options.feedItemsRoot - The container element whose direct children are feed items.
   * @param {object} options.config - Configuration for the event payload.
   * @param {string} options.config.categoryClick - The category string for click events.
   * @param {string} options.config.categoryImpression - The category string for impression events.
   * @param {string} options.config.contextType - The context type for the feed.
   * @param {string} options.config.feedConfigId - The configuration ID for the feed.
   * @param {string} [options.contentIdAttribute='feedContentId'] - The data attribute on feed items that holds the article/content ID.
   */
  constructor({ feedItemsRoot, config, contentIdAttribute = 'feedContentId' }) {
    if (!feedItemsRoot || !config) {
      console.error('FeedTracker: Missing required constructor options.');
      return;
    }

    this.feedItemsRoot = feedItemsRoot;
    this.config = config;
    this.contentIdAttribute = contentIdAttribute;

    this.queue = [];
    this.processInterval = null;
    this.inFlight = false;
    this.pendingBatch = null;
    this.failures = 0;
    this.nextAttemptAt = 0;
    this.nextFeedPosition = 1;

    // Bind methods to ensure `this` is correctly referenced in callbacks.
    this.trackFeedImpressions = this.trackFeedImpressions.bind(this);
    this.trackFeedClickListener = this.trackFeedClickListener.bind(this);
    this.submitEventsBatch = this.submitEventsBatch.bind(this);

    this.observer = new IntersectionObserver(this.trackFeedImpressions, {
      root: null,
      rootMargin: '0px',
      threshold: VISIBLE_THRESHOLD,
    });
  }

  /**
   * Initializes the tracker, finds feed items, and sets up listeners.
   */
  init() {
    this.processInterval ||= setInterval(
      this.submitEventsBatch,
      AUTOSEND_PERIOD,
    );
    this.observer.disconnect();
    this.nextFeedPosition = 1;

    this.findAndTrackFeedItems(this.feedItemsRoot);
    this.ensureQueueIsClearedBeforeExit();
  }

  /**
   * Recursively finds and begins tracking feed items within a given root element.
   * @param {HTMLElement} root The element to search within for feed items.
   */
  findAndTrackFeedItems(root) {
    Array.from(root.children).forEach((/** @type HTMLElement */ element) => {
      // Handle nested containers, like those from `initScrolling.js`
      if (element.classList.contains('paged-stories')) {
        this.findAndTrackFeedItems(element);
      } else if (element.dataset?.[this.contentIdAttribute]) {
        // Standardize the content ID attribute for easier processing
        element.dataset.feedContentId =
          element.dataset[this.contentIdAttribute];
        element.dataset.feedPosition = this.nextFeedPosition;

        // Also captures right-click opens
        element.addEventListener(
          'mousedown',
          this.trackFeedClickListener,
          true,
        );
        this.observer.observe(element);

        this.nextFeedPosition += 1;
      }
    });
  }

  /**
   * Sets up listeners to send pending events before the page unloads.
   */
  ensureQueueIsClearedBeforeExit() {
    // Use a flag to ensure listeners are only attached once per instance.
    if (this.exitListenersAttached) return;

    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'hidden') {
        this.flushBeforeExit();
      } else if (this.feedItemsRoot.isConnected) {
        this.init();
        this.submitEventsBatch();
      }
    });
    window.addEventListener('pagehide', () => this.flushBeforeExit());
    window.addEventListener('online', this.submitEventsBatch);

    this.exitListenersAttached = true;
  }

  /**
   * IntersectionObserver callback to queue impression events.
   * @param {IntersectionObserverEntry[]} entries
   */
  trackFeedImpressions(entries) {
    if (document.visibilityState === 'hidden') return;
    entries.forEach((entry) => {
      if (
        entry.isIntersecting &&
        entry.intersectionRatio >= VISIBLE_THRESHOLD
      ) {
        const post = /** @type {HTMLElement} */ (entry.target);
        if (!post.dataset.impressionRecorded) {
          this.queueEvent(post, this.config.categoryImpression);
          post.dataset.impressionRecorded = 'true';
        }
      }
    });
  }

  /**
   * Event listener callback to queue click events.
   * @param {MouseEvent} event
   */
  trackFeedClickListener(event) {
    const post = /** @type {HTMLElement} */ (event.currentTarget);

    if (!post.dataset.clickRecorded) {
      this.queueEvent(post, this.config.categoryClick);
      post.dataset.clickRecorded = 'true';
      // Clicks are high-value signals, send immediately.
      this.submitEventsBatch();
    }
  }

  /**
   * Adds a structured event to the queue.
   * @param {HTMLElement} post The feed item element.
   * @param {string} category The event category (e.g., 'feed_click').
   */
  queueEvent(post, category) {
    const { feedContentId, feedPosition } = post.dataset;

    this.queue.push({
      event_id: createEventId(),
      article_id: feedContentId,
      article_position: feedPosition,
      category,
      feed_config_id: this.config.feedConfigId,
      context_type: this.config.contextType,
    });

    if (this.queue.length > MAX_QUEUE_SIZE) {
      const oldestImpression = this.queue.findIndex(
        (event) => event.category === this.config.categoryImpression,
      );
      this.queue.splice(oldestImpression === -1 ? 0 : oldestImpression, 1);
    }

    if (this.queue.length >= MAX_BATCH_SIZE) {
      this.submitEventsBatch();
    }
  }

  /** All send paths share the deadline, including clicks and exit beacons. */
  canAttempt(exiting = false) {
    return (
      this.queue.length > 0 &&
      navigator.onLine !== false &&
      (exiting || document.visibilityState !== 'hidden') &&
      Date.now() >= this.nextAttemptAt
    );
  }

  /** Freeze the retry batch so newer arrivals do not consume its attempt budget. */
  currentBatch() {
    if (this.pendingBatch) {
      const queued = new Set(this.queue.map((event) => event.event_id));
      this.pendingBatch.events = this.pendingBatch.events.filter((event) =>
        queued.has(event.event_id),
      );
      if (this.pendingBatch.events.length === 0) this.pendingBatch = null;
    }
    this.pendingBatch ||= {
      events: this.queue.slice(0, MAX_BATCH_SIZE),
      attempts: 0,
    };
    return this.pendingBatch;
  }

  /** Remove only this batch, preserving events appended during the request. */
  finishBatch(batch) {
    const ids = new Set(batch.events.map((event) => event.event_id));
    this.queue = this.queue.filter((event) => !ids.has(event.event_id));
    if (this.pendingBatch === batch) this.pendingBatch = null;
  }

  /** Retry transient failures with full jitter and either Retry-After form. */
  scheduleRetry(batch, response) {
    const header = response?.headers?.get('Retry-After');
    const seconds = header == null ? NaN : Number(header);
    const retryAfter = Number.isFinite(seconds)
      ? seconds * 1000
      : Date.parse(header) - Date.now();
    this.failures += 1;
    const ceiling = Math.min(
      MAX_RETRY_DELAY,
      AUTOSEND_PERIOD * 2 ** (this.failures - 1),
    );
    this.nextAttemptAt =
      Date.now() + Math.max(Math.random() * ceiling, retryAfter || 0);
    if (batch.attempts >= MAX_ATTEMPTS) this.finishBatch(batch);
  }

  /** Sends one acknowledged batch, with at most six transmissions per batch. */
  async submitEventsBatch({ exiting = false } = {}) {
    if (this.inFlight || !this.canAttempt(exiting)) return;

    const batch = this.currentBatch();
    batch.attempts += 1;
    this.inFlight = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT);
    try {
      const response = await window.fetch('/feed_events', {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')
            ?.content,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ feed_events: batch.events }),
        credentials: 'same-origin',
        keepalive: true,
      });
      if (response.ok) {
        this.finishBatch(batch);
        this.failures = 0;
        this.nextAttemptAt = 0;
      } else if (
        response.status === 408 ||
        response.status === 429 ||
        response.status >= 500
      ) {
        this.scheduleRetry(batch, response);
      } else {
        // Permanent errors (including CSRF 422) cannot be repaired by replay.
        this.finishBatch(batch);
        this.failures = 0;
        this.nextAttemptAt = Date.now() + AUTOSEND_PERIOD;
      }
    } catch (error) {
      this.scheduleRetry(batch);
    } finally {
      clearTimeout(timeout);
      this.inFlight = false;
    }
  }

  /** Make at most one exit attempt, without bypassing backoff or offline checks. */
  flushBeforeExit() {
    if (!this.canAttempt(true)) return;
    const batch = this.currentBatch();
    const payload = {
      authenticity_token: document.querySelector('meta[name="csrf-token"]')
        ?.content,
      feed_events: batch.events,
    };
    const data = new Blob([JSON.stringify(payload)], {
      type: 'application/json',
    });
    if (!navigator.sendBeacon || !navigator.sendBeacon('/feed_events', data)) {
      this.submitEventsBatch({ exiting: true });
      return;
    }
    // Beacon acceptance is not an acknowledgement. Count it against the retry
    // budget and retain the IDs until acknowledged or the budget is exhausted.
    batch.attempts += 1;
    this.scheduleRetry(batch);
    this.nextAttemptAt = Math.max(
      this.nextAttemptAt,
      Date.now() + AUTOSEND_PERIOD,
    );
  }
}

/**
 * Sets up the main home feed events tracker.
 * Called every time posts are inserted into the feed.
 */
export function observeFeedElements() {
  const feedContainer = document.getElementById('index-container');
  const feedItemsRoot = document.getElementById('rendered-article-feed');

  if (!(feedContainer && feedItemsRoot)) return;

  const {
    feedCategoryClick,
    feedCategoryImpression,
    feedContextType,
    feedConfigId,
  } = feedContainer.dataset;

  // Use a static property to hold the instance, ensuring it's only created once.
  if (!window.mainFeedTracker) {
    window.mainFeedTracker = new FeedTracker({
      feedItemsRoot,
      config: {
        categoryClick: feedCategoryClick,
        categoryImpression: feedCategoryImpression,
        contextType: feedContextType,
        feedConfigId: feedConfigId,
      },
      contentIdAttribute: 'feedContentId',
    });
  } else {
    window.mainFeedTracker.feedItemsRoot = feedItemsRoot;
    window.mainFeedTracker.config.categoryClick = feedCategoryClick;
    window.mainFeedTracker.config.categoryImpression = feedCategoryImpression;
    window.mainFeedTracker.config.contextType = feedContextType;
    window.mainFeedTracker.config.feedConfigId = feedConfigId;
  }

  // Re-initialize to observe new elements.
  window.mainFeedTracker.init();
}

window.observeFeedElements = observeFeedElements;
