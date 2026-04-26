import fetchMock from 'jest-fetch-mock';
import {
  withRetry,
  callHistoricalAPI,
  callReferrersAPI,
  callTotalsAPI,
  callTopContributorsAPI,
  callFollowerEngagementAPI,
  callDashboardAPI,
} from '../client';

/* global globalThis */

describe('analytics/client', () => {
  beforeAll(() => {
    globalThis.fetch = fetchMock;
  });

  beforeEach(() => {
    fetchMock.resetMocks();
  });

  afterAll(() => {
    delete globalThis.fetch;
  });

  describe('withRetry', () => {
    it('resolves without retry when fn succeeds on the first try', async () => {
      const fn = jest.fn().mockResolvedValue('ok');

      await expect(withRetry(fn, { baseDelayMs: 0 })).resolves.toBe('ok');
      expect(fn).toHaveBeenCalledTimes(1);
    });

    it('retries once on TypeError and resolves on the second attempt', async () => {
      const fn = jest
        .fn()
        .mockRejectedValueOnce(new TypeError('Failed to fetch'))
        .mockResolvedValueOnce('ok');

      await expect(withRetry(fn, { baseDelayMs: 0 })).resolves.toBe('ok');
      expect(fn).toHaveBeenCalledTimes(2);
    });

    it('rejects with the final error after exhausting retries', async () => {
      const fn = jest.fn().mockRejectedValue(new TypeError('Failed to fetch'));

      await expect(withRetry(fn, { baseDelayMs: 0 })).rejects.toThrow('Failed to fetch');
      expect(fn).toHaveBeenCalledTimes(2); // initial + 1 retry
    });

    it('does NOT retry on non-TypeError (e.g. 4xx/5xx from handleFetchAPIErrors)', async () => {
      const fn = jest.fn().mockRejectedValue(new Error('Not Found'));

      await expect(withRetry(fn, { baseDelayMs: 0 })).rejects.toThrow('Not Found');
      expect(fn).toHaveBeenCalledTimes(1);
    });

    it('honors a custom maxRetries count', async () => {
      const fn = jest.fn().mockRejectedValue(new TypeError('network down'));

      await expect(
        withRetry(fn, { maxRetries: 3, baseDelayMs: 0 }),
      ).rejects.toThrow('network down');
      expect(fn).toHaveBeenCalledTimes(4); // initial + 3 retries
    });
  });

  describe('call*API URL construction', () => {
    const date = new Date('2024-05-01T12:00:00Z');

    beforeEach(() => {
      fetchMock.mockResponseOnce(JSON.stringify({ ok: true }));
    });

    it('callHistoricalAPI hits the historical endpoint with start+org+article params', async () => {
      await callHistoricalAPI(date, { organizationId: 42, articleId: 7 });

      expect(fetchMock).toHaveBeenCalledWith(
        '/api/analytics/historical?start=2024-05-01&organization_id=42&article_id=7',
      );
    });

    it('callReferrersAPI hits the referrers endpoint', async () => {
      await callReferrersAPI(date, {});

      expect(fetchMock).toHaveBeenCalledWith('/api/analytics/referrers?start=2024-05-01');
    });

    it('callTotalsAPI hits the totals endpoint', async () => {
      await callTotalsAPI(date, { organizationId: 99 });

      expect(fetchMock).toHaveBeenCalledWith(
        '/api/analytics/totals?start=2024-05-01&organization_id=99',
      );
    });

    it('callTopContributorsAPI hits the top_contributors endpoint', async () => {
      await callTopContributorsAPI(date, { articleId: 5 });

      expect(fetchMock).toHaveBeenCalledWith(
        '/api/analytics/top_contributors?start=2024-05-01&article_id=5',
      );
    });

    it('callFollowerEngagementAPI hits the follower_engagement endpoint', async () => {
      await callFollowerEngagementAPI(date, { organizationId: 3 });

      expect(fetchMock).toHaveBeenCalledWith(
        '/api/analytics/follower_engagement?start=2024-05-01&organization_id=3',
      );
    });

    it('callDashboardAPI hits the dashboard endpoint with start+org+article params', async () => {
      await callDashboardAPI(date, { organizationId: 42, articleId: 7 });

      expect(fetchMock).toHaveBeenCalledWith(
        '/api/analytics/dashboard?start=2024-05-01&organization_id=42&article_id=7',
      );
    });

    it('callDashboardAPI works with no context args', async () => {
      await callDashboardAPI(date);

      expect(fetchMock).toHaveBeenCalledWith('/api/analytics/dashboard?start=2024-05-01');
    });
  });

  describe('call*API error + retry integration', () => {
    const date = new Date('2024-05-01T12:00:00Z');

    it('parses the response JSON on success', async () => {
      fetchMock.mockResponseOnce(JSON.stringify({ stat: 123 }));

      await expect(callHistoricalAPI(date, {})).resolves.toEqual({ stat: 123 });
    });

    it('retries once on network failure and resolves on the second attempt', async () => {
      fetchMock
        .mockRejectOnce(new TypeError('Failed to fetch'))
        .mockResponseOnce(JSON.stringify({ stat: 'recovered' }));

      await expect(callHistoricalAPI(date, {})).resolves.toEqual({ stat: 'recovered' });
      expect(fetchMock).toHaveBeenCalledTimes(2);
    });

    it('rejects with API error message from JSON body on 4xx (no retry)', async () => {
      fetchMock.mockResponseOnce(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        statusText: 'Unauthorized',
      });

      await expect(callHistoricalAPI(date, {})).rejects.toThrow('Unauthorized');
      expect(fetchMock).toHaveBeenCalledTimes(1);
    });

    it('rejects with statusText on non-JSON 5xx response (no retry)', async () => {
      fetchMock.mockResponseOnce('<html>500</html>', {
        status: 500,
        statusText: 'Internal Server Error',
      });

      await expect(callHistoricalAPI(date, {})).rejects.toThrow('Internal Server Error');
      expect(fetchMock).toHaveBeenCalledTimes(1);
    });
  });
});
