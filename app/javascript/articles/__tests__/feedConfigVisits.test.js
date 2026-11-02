import { webcrypto } from 'crypto';
import { FeedConfigVisitTracker } from '../feedConfigVisits';

describe('FeedConfigVisitTracker', () => {
  let tracker;
  let visibility;
  let online;
  let isCurrent;
  let originalCrypto;
  const response = (status = 200, headers = {}) => ({
    status,
    ok: status >= 200 && status < 300,
    headers: { get: (key) => headers[key] ?? (key === 'X-Feed-Visit-Wait' ? '1800' : null) },
  });
  const flush = async () => { await Promise.resolve(); await Promise.resolve(); };
  const body = (index = 0) => JSON.parse(window.fetch.mock.calls[index][1].body);

  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-11-02T12:00:00Z'));
    originalCrypto = window.crypto;
    Object.defineProperty(window, 'crypto', { configurable: true, value: webcrypto });
    visibility = jest.spyOn(document, 'visibilityState', 'get').mockReturnValue('visible');
    online = jest.spyOn(navigator, 'onLine', 'get').mockReturnValue(true);
    jest.spyOn(Math, 'random').mockReturnValue(0);
    window.csrfToken = 'csrf';
    window.fetch = jest.fn().mockResolvedValue(response());
    isCurrent = jest.fn(() => true);
    tracker = new FeedConfigVisitTracker('signed-proof', isCurrent);
  });

  afterEach(() => {
    tracker.stop();
    jest.clearAllTimers();
    jest.useRealTimers();
    jest.restoreAllMocks();
    Object.defineProperty(window, 'crypto', { configurable: true, value: originalCrypto });
    delete window.csrfToken;
  });

  it('acknowledges rendering with a UUID and CSRF protection', async () => {
    tracker.start();
    await flush();
    expect(window.fetch).toHaveBeenCalledWith('/feed_config_visits', expect.objectContaining({
      method: 'POST', credentials: 'same-origin', headers: expect.objectContaining({ 'X-CSRF-Token': 'csrf' }),
    }));
    expect(body()).toEqual({ visit_token: 'signed-proof', event_id: expect.stringMatching(/^[0-9a-f-]{36}$/) });
  });

  it('waits for a background-loaded feed to become visible', async () => {
    visibility.mockReturnValue('hidden');
    tracker.start();
    expect(window.fetch).not.toHaveBeenCalled();
    visibility.mockReturnValue('visible');
    document.dispatchEvent(new Event('visibilitychange'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('fails closed without breaking the feed when crypto is unavailable', async () => {
    Object.defineProperty(window, 'crypto', { configurable: true, value: undefined });
    expect(() => tracker.start()).not.toThrow();
    window.dispatchEvent(new Event('focus'));
    await flush();
    expect(window.fetch).not.toHaveBeenCalled();
  });

  it('supports browsers with getRandomValues but without randomUUID', async () => {
    Object.defineProperty(window, 'crypto', {
      configurable: true, value: { getRandomValues: webcrypto.getRandomValues.bind(webcrypto) },
    });
    tracker.start();
    await flush();
    expect(body().event_id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });

  it('deduplicates pageshow, visibility, and focus events for the same visit', async () => {
    tracker.start();
    document.dispatchEvent(new Event('visibilitychange'));
    window.dispatchEvent(new Event('pageshow'));
    window.dispatchEvent(new Event('focus'));
    await flush();
    window.dispatchEvent(new Event('focus'));
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('records a fresh event on a later browser-history restore', async () => {
    tracker.start();
    await flush();
    const firstId = body().event_id;
    jest.advanceTimersByTime(30 * 60 * 1000);
    window.dispatchEvent(new Event('pageshow'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(2);
    expect(body(1).event_id).not.toBe(firstId);
  });

  it('never generates periodic return credit for an idle foreground tab', async () => {
    tracker.start();
    await flush();
    jest.advanceTimersByTime(60 * 60 * 1000);
    window.dispatchEvent(new Event('online'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('uses the server cooldown rather than a fixed client interval', async () => {
    window.fetch.mockResolvedValue(response(200, { 'X-Feed-Visit-Wait': '3600' }));
    tracker.start();
    await flush();
    jest.advanceTimersByTime(30 * 60 * 1000);
    window.dispatchEvent(new Event('focus'));
    expect(window.fetch).toHaveBeenCalledTimes(1);
    jest.advanceTimersByTime(30 * 60 * 1000);
    window.dispatchEvent(new Event('focus'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(2);
  });

  it('does not count detached feeds or another route', async () => {
    isCurrent.mockReturnValue(false);
    tracker.start();
    window.dispatchEvent(new Event('pageshow'));
    await flush();
    expect(window.fetch).not.toHaveBeenCalled();
  });

  it('retries transient failures with the original event ID', async () => {
    window.fetch.mockResolvedValueOnce(response(503));
    tracker.start();
    await flush();
    jest.advanceTimersByTime(1000);
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(2);
    expect(body(1)).toEqual(body());
  });

  it('honors Retry-After even when visibility events arrive during backoff', async () => {
    window.fetch.mockResolvedValueOnce(response(429, { 'Retry-After': '60' }));
    tracker.start();
    await flush();
    jest.advanceTimersByTime(59000);
    window.dispatchEvent(new Event('focus'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
    jest.advanceTimersByTime(1000);
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(2);
    expect(body(1)).toEqual(body());
  });

  it('pauses retries while hidden and resumes the same event on return', async () => {
    window.fetch.mockRejectedValueOnce(new Error('offline'));
    tracker.start();
    await flush();
    visibility.mockReturnValue('hidden');
    jest.advanceTimersByTime(60000);
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
    visibility.mockReturnValue('visible');
    document.dispatchEvent(new Event('visibilitychange'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(2);
    expect(body(1)).toEqual(body());
  });

  it('honors HTTP-date Retry-After values longer than the normal backoff cap', async () => {
    window.fetch.mockResolvedValueOnce(response(429, {
      'Retry-After': new Date(Date.now() + 3600000).toUTCString(),
    }));
    tracker.start();
    await flush();
    jest.advanceTimersByTime(300000);
    window.dispatchEvent(new Event('focus'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
    jest.advanceTimersByTime(3300000);
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(2);
  });

  it('waits for online without manufacturing a new visit', async () => {
    online.mockReturnValue(false);
    tracker.start();
    expect(window.fetch).not.toHaveBeenCalled();
    online.mockReturnValue(true);
    window.dispatchEvent(new Event('online'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
    jest.advanceTimersByTime(3600000);
    window.dispatchEvent(new Event('online'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('waits for the asynchronous CSRF bootstrap', async () => {
    delete window.csrfToken;
    tracker.start();
    expect(window.fetch).not.toHaveBeenCalled();
    window.csrfToken = 'ready';
    jest.advanceTimersByTime(1000);
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it.each([204, 400, 401, 403, 422])('stops on permanent status %s', async (status) => {
    window.fetch.mockResolvedValueOnce(response(status));
    tracker.start();
    await flush();
    jest.advanceTimersByTime(3600000);
    window.dispatchEvent(new Event('focus'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('bounds transient retries and never spins in the background', async () => {
    window.fetch.mockRejectedValue(new Error('unavailable'));
    tracker.start();
    await flush();
    for (let attempt = 0; attempt < 10; attempt += 1) {
      jest.advanceTimersByTime(1000);
      await flush();
    }
    expect(window.fetch).toHaveBeenCalledTimes(6);
    jest.advanceTimersByTime(3600000);
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(6);
  });

  it('times out hanging requests and reuses their event IDs', async () => {
    window.fetch.mockImplementationOnce((url, { signal }) => new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted')));
    }));
    tracker.start();
    jest.advanceTimersByTime(10000);
    await flush();
    jest.advanceTimersByTime(1000);
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(2);
    expect(body(1)).toEqual(body());
  });

  it('cleans up retries and listeners when the feed unmounts', async () => {
    window.fetch.mockResolvedValueOnce(response(503));
    tracker.start();
    await flush();
    tracker.stop();
    jest.advanceTimersByTime(3600000);
    document.dispatchEvent(new Event('visibilitychange'));
    window.dispatchEvent(new Event('pageshow'));
    window.dispatchEvent(new Event('focus'));
    await flush();
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });

  it('aborts in-flight delivery on unmount without retrying it', async () => {
    window.fetch.mockImplementationOnce((url, { signal }) => new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted')));
    }));
    tracker.start();
    const { signal } = window.fetch.mock.calls[0][1];
    tracker.stop();
    await flush();
    jest.advanceTimersByTime(60000);
    await flush();
    expect(signal.aborted).toBe(true);
    expect(window.fetch).toHaveBeenCalledTimes(1);
  });
});
