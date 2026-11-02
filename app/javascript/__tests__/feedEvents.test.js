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
    jest.useFakeTimers();
    jest.spyOn(Math, 'random').mockReturnValue(0.5);
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
    jest.restoreAllMocks();
    jest.useRealTimers();
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
    jest.advanceTimersByTime(5000);
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
    expect(tracker.nextAttemptAt).toBe(0);
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
      jest.advanceTimersByTime(5000);
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
  it('backs off every send path after a failure', async () => {
    window.fetch.mockResolvedValue({ ok: false, status: 500 });
    see();
    await tracker.submitEventsBatch();
    expect(tracker.nextAttemptAt - Date.now()).toBe(2500);
    await tracker.submitEventsBatch();
    tracker.flushBeforeExit();
    for (let index = 0; index < 20; index += 1)
      tracker.queueEvent(post, 'impression');
    tracker.trackFeedClickListener({ currentTarget: post });
    expect(window.fetch).toHaveBeenCalledTimes(1);
    expect(navigator.sendBeacon).not.toHaveBeenCalled();
    jest.advanceTimersByTime(2500);
    await tracker.submitEventsBatch();
    expect(window.fetch).toHaveBeenCalledTimes(2);
    expect(tracker.nextAttemptAt - Date.now()).toBe(5000);
  });

  it.each([400, 401, 403, 413, 422])(
    'drops permanent HTTP %s failures',
    async (status) => {
      window.fetch.mockResolvedValue({ ok: false, status });
      see();
      await tracker.submitEventsBatch();
      jest.advanceTimersByTime(500000);
      await tracker.submitEventsBatch();
      expect(tracker.queue).toHaveLength(0);
      expect(window.fetch).toHaveBeenCalledTimes(1);
    },
  );

  it.each([408, 429, 503])(
    'honors numeric Retry-After on transient HTTP %s failures',
    async (status) => {
      window.fetch.mockResolvedValue({
        ok: false,
        status,
        headers: { get: () => '120' },
      });
      see();
      await tracker.submitEventsBatch();
      jest.advanceTimersByTime(119000);
      await tracker.submitEventsBatch();
      expect(window.fetch).toHaveBeenCalledTimes(1);
      jest.advanceTimersByTime(1000);
      await tracker.submitEventsBatch();
      expect(window.fetch).toHaveBeenCalledTimes(2);
    },
  );

  it('honors an HTTP-date Retry-After', async () => {
    const until = new Date(Date.now() + 120000).toUTCString();
    window.fetch.mockResolvedValue({
      ok: false,
      status: 503,
      headers: { get: () => until },
    });
    see();
    await tracker.submitEventsBatch();
    expect(tracker.nextAttemptAt).toBe(Date.parse(until));
  });

  it('drops only the failed batch after six attempts and preserves later arrivals', async () => {
    window.fetch.mockResolvedValue({ ok: false, status: 500 });
    see();
    await tracker.submitEventsBatch();
    tracker.queueEvent(post, 'click');
    for (let attempt = 1; attempt < 6; attempt += 1) {
      jest.advanceTimersByTime(300000);
      await tracker.submitEventsBatch();
    }
    expect(window.fetch).toHaveBeenCalledTimes(6);
    expect(tracker.queue.map((event) => event.category)).toEqual(['click']);
    window.fetch.mockResolvedValue({ ok: true });
    jest.advanceTimersByTime(300000);
    await tracker.submitEventsBatch();
    expect(tracker.queue).toHaveLength(0);
  });

  it('bounds the queue while retaining clicks ahead of impressions', async () => {
    Object.defineProperty(navigator, 'onLine', {
      configurable: true,
      value: false,
    });
    try {
      tracker.queueEvent(post, 'click');
      const clickId = tracker.queue[0].event_id;
      for (let index = 0; index < 250; index += 1)
        tracker.queueEvent(post, 'impression');
      expect(tracker.queue).toHaveLength(200);
      expect(tracker.queue[0].event_id).toBe(clickId);
      await tracker.submitEventsBatch();
      tracker.flushBeforeExit();
      expect(window.fetch).not.toHaveBeenCalled();
      expect(navigator.sendBeacon).not.toHaveBeenCalled();
    } finally {
      delete navigator.onLine;
    }
  });

  it('does not retry a hidden tab or repeat its exit beacon immediately', async () => {
    see();
    Object.defineProperty(document, 'visibilityState', {
      configurable: true,
      value: 'hidden',
    });
    try {
      await tracker.submitEventsBatch();
      expect(window.fetch).not.toHaveBeenCalled();
      tracker.flushBeforeExit();
      tracker.flushBeforeExit();
      expect(navigator.sendBeacon).toHaveBeenCalledTimes(1);
    } finally {
      delete document.visibilityState;
    }
  });
  it('counts exit beacons against the same six-attempt budget', () => {
    see();
    for (let attempt = 0; attempt < 6; attempt += 1) {
      tracker.flushBeforeExit();
      jest.advanceTimersByTime(300000);
    }
    tracker.flushBeforeExit();
    expect(navigator.sendBeacon).toHaveBeenCalledTimes(6);
    expect(tracker.queue).toHaveLength(0);
  });
  it('does not reset outage backoff when queue pressure evicts a failed batch', async () => {
    window.fetch.mockResolvedValue({ ok: false, status: 500 });
    see();
    await tracker.submitEventsBatch();
    for (let index = 0; index < 250; index += 1)
      tracker.queueEvent(post, 'impression');
    jest.advanceTimersByTime(2500);
    await tracker.submitEventsBatch();
    expect(tracker.nextAttemptAt - Date.now()).toBe(5000);
  });
});
