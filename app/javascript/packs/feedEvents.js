const MAX_BATCH_SIZE = 20;
const AUTOSEND_PERIOD = 5 * 1000;
const VISIBLE_THRESHOLD = 0.25;

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
    this.beaconEnabled = true;
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
    this.processInterval ||= setInterval(this.submitEventsBatch, AUTOSEND_PERIOD);
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
        element.dataset.feedContentId = element.dataset[this.contentIdAttribute];
        element.dataset.feedPosition = this.nextFeedPosition;
        
        // Also captures right-click opens
        element.addEventListener('mousedown', this.trackFeedClickListener, true);
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
      if (document.visibilityState == 'hidden') this.submitEventsBatch();
    });
    window.addEventListener('beforeunload', this.submitEventsBatch);
    
    this.exitListenersAttached = true;
  }

  /**
   * IntersectionObserver callback to queue impression events.
   * @param {IntersectionObserverEntry[]} entries
   */
  trackFeedImpressions(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting && entry.intersectionRatio >= VISIBLE_THRESHOLD) {
        queueMicrotask(() => {
          const post = /** @type {HTMLElement} */ (entry.target);
          if (!post.dataset.impressionRecorded) {
            this.queueEvent(post, this.config.categoryImpression);
            post.dataset.impressionRecorded = 'true';
          }
        });
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
      article_id: feedContentId,
      article_position: feedPosition,
      category,
      feed_config_id: this.config.feedConfigId,
      context_type: this.config.contextType,
    });

    if (this.queue.length >= MAX_BATCH_SIZE) {
      this.submitEventsBatch();
    }
  }

  /**
   * Sends the current batch of queued events to the server.
   */
  submitEventsBatch() {
    if (this.queue.length === 0) return;

    const tokenMeta = document.querySelector("meta[name='csrf-token']");
    const authenticity_token = tokenMeta?.getAttribute('content');
    const eventsToSend = [...this.queue];
    this.queue = [];

    const payload = { authenticity_token, feed_events: eventsToSend };

    if (this.beaconEnabled && navigator.sendBeacon) {
      const data = new Blob([JSON.stringify(payload)], { type: 'application/json' });
      if (!navigator.sendBeacon('/feed_events', data)) {
        this.beaconEnabled = false;
        this.fallbackRequest(authenticity_token, eventsToSend);
      }
    } else {
      this.fallbackRequest(authenticity_token, eventsToSend);
    }
  }
  
  /**
   * Fallback request using fetch with keepalive.
   * @param {string} authenticity_token
   * @param {Array<object>} events
   */
  fallbackRequest(authenticity_token, events) {
    window
      .fetch('/feed_events', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': authenticity_token,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ feed_events: events }),
        credentials: 'same-origin',
        keepalive: true,
      })
      .catch((error) => console.error(error));
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

  const { feedCategoryClick, feedCategoryImpression, feedContextType, feedConfigId } = feedContainer.dataset;
  
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
      contentIdAttribute: 'feedContentId'
    });
  }
  
  // Re-initialize to observe new elements.
  window.mainFeedTracker.init();
}

window.observeFeedElements = observeFeedElements;