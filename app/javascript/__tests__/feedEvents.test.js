import { webcrypto } from 'crypto';
import { FeedTracker } from '../packs/feedEvents';

describe('feed impression delivery', () => {
  let tracker;
  let post;
  let originalFetch;
  let originalObserver;
  let originalBeacon;
  let originalCrypto;

  beforeEach(() => {
    originalCrypto = window.crypto;
    Object.defineProperty(window, 'crypto', {
      configurable: true,
      value: webcrypto,
    });
    originalFetch = window.fetch;
    originalObserver = window.IntersectionObserver;
    originalBeacon = navigator.sendBeacon;
    window.IntersectionObserver = jest.fn(() => ({
      observe: jest.fn(),
      disconnect: jest.fn(),
    }));
    window.fetch = jest.fn().mockResolvedValue({ ok: true });
    navigator.sendBeacon = jest.fn().mockReturnValue(true);
    document.body.innerHTML =
      '<div id="feed"><div data-feed-content-id="7" data-feed-position="1"></div></div>';
    post = document.querySelector('[data-feed-content-id]');
    tracker = new FeedTracker({
      feedItemsRoot: document.getElementById('feed'),
      config: {
        categoryImpression: 'impression',
        categoryClick: 'click',
        contextType: 'home',
      },
    });
  });

  afterEach(() => {
    Object.defineProperty(window, 'crypto', {
      configurable: true,
      value: originalCrypto,
    });
    window.fetch = originalFetch;
    window.IntersectionObserver = originalObserver;
    navigator.sendBeacon = originalBeacon;
  });

  function see(ratio = 0.25) {
    tracker.trackFeedImpressions([
      { target: post, isIntersecting: true, intersectionRatio: ratio },
    ]);
  }

  it('counts once per DOM card only after the visibility threshold', () => {
    see(0.24);
    expect(tracker.queue).toHaveLength(0);
    see();
    see();
    expect(tracker.queue).toHaveLength(1);
    expect(tracker.queue[0]).toMatchObject({
      article_id: '7',
      category: 'impression',
      context_type: 'home',
    });
    expect(tracker.queue[0].event_id).toMatch(
      /^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/,
    );
  });

  it('does not count impressions while the document is hidden', () => {
    const visibility = Object.getOwnPropertyDescriptor(
      document,
      'visibilityState',
    );
    Object.defineProperty(document, 'visibilityState', {
      configurable: true,
      value: 'hidden',
    });
    see();
    expect(tracker.queue).toHaveLength(0);
    if (visibility)
      Object.defineProperty(document, 'visibilityState', visibility);
    else delete document.visibilityState;
    see();
    expect(tracker.queue).toHaveLength(1);
  });

  it('batches queued events without discarding the unsent remainder', async () => {
    const send = jest.spyOn(tracker, 'submitEventsBatch');
    for (let index = 0; index < 25; index += 1)
      tracker.queueEvent(post, 'impression');
    // Reaching 20 starts the first request automatically.
    await send.mock.results[0].value;
    expect(
      JSON.parse(window.fetch.mock.calls[0][1].body).feed_events,
    ).toHaveLength(20);
    expect(tracker.queue).toHaveLength(5);
    await tracker.submitEventsBatch();
    expect(tracker.queue).toHaveLength(0);
  });

  it('retries a network failure with the original event ID', async () => {
    window.fetch.mockRejectedValueOnce(new Error('offline'));
    see();
    const id = tracker.queue[0].event_id;
    await tracker.submitEventsBatch();
    expect(tracker.queue[0].event_id).toBe(id);
    await tracker.submitEventsBatch();
    expect(tracker.queue).toHaveLength(0);
    const payloads = window.fetch.mock.calls.map(([, request]) =>
      JSON.parse(request.body),
    );
    expect(payloads[0]).toEqual(payloads[1]);
  });

  it('retains events on HTTP errors rather than treating them as acknowledged', async () => {
    window.fetch.mockResolvedValueOnce({ ok: false, status: 503 });
    see();
    await tracker.submitEventsBatch();
    expect(tracker.queue).toHaveLength(1);
  });

  it('allows one request at a time and keeps events queued during an in-flight request', async () => {
    let acknowledge;
    window.fetch.mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          acknowledge = resolve;
        }),
    );
    see();
    const pending = tracker.submitEventsBatch();
    await tracker.submitEventsBatch();
    tracker.queueEvent(post, 'click');
    acknowledge({ ok: true });
    await pending;
    expect(window.fetch).toHaveBeenCalledTimes(1);
    expect(tracker.queue).toHaveLength(1);
    expect(tracker.queue[0].category).toBe('click');
  });

  it('keeps queued beacons available for retry, including an unacknowledged fetch', async () => {
    let acknowledge;
    window.fetch.mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          acknowledge = resolve;
        }),
    );
    see();
    const pending = tracker.submitEventsBatch();
    tracker.flushBeforeExit();
    expect(navigator.sendBeacon).toHaveBeenCalledWith(
      '/feed_events',
      expect.any(Blob),
    );
    expect(tracker.queue).toHaveLength(1);
    acknowledge({ ok: true });
    await pending;
    expect(tracker.queue).toHaveLength(0);
  });

  it('retries a request that times out without losing its event ID', async () => {
    jest.useFakeTimers();
    try {
      window.fetch.mockImplementationOnce(
        (url, options) =>
          new Promise((resolve, reject) => {
            options.signal.addEventListener('abort', () =>
              reject(new Error('aborted')),
            );
          }),
      );
      see();
      const id = tracker.queue[0].event_id;
      const request = tracker.submitEventsBatch();
      jest.advanceTimersByTime(10000);
      await request;
      expect(tracker.queue[0].event_id).toBe(id);
      await tracker.submitEventsBatch();
      expect(tracker.queue).toHaveLength(0);
    } finally {
      jest.useRealTimers();
    }
  });

  it('uses keepalive fetch when beacons are unavailable', async () => {
    navigator.sendBeacon = undefined;
    see();
    tracker.flushBeforeExit();
    expect(window.fetch).toHaveBeenCalledWith(
      '/feed_events',
      expect.objectContaining({ keepalive: true }),
    );
    await Promise.resolve();
  });

  it('does not lose a batch when the browser refuses to queue its beacon', () => {
    navigator.sendBeacon.mockReturnValue(false);
    see();
    tracker.flushBeforeExit();
    expect(tracker.queue).toHaveLength(1);
    expect(window.fetch).toHaveBeenCalledWith(
      '/feed_events',
      expect.objectContaining({ keepalive: true }),
    );
  });
});
