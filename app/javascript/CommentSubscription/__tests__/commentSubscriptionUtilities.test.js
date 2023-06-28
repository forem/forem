import fetch from 'jest-fetch-mock';
import {
  getCommentSubscriptionStatus,
  setCommentSubscriptionStatus,
} from '../commentSubscriptionUtilities';

const csrfToken = 'this-is-a-csrf-token';
jest.mock('../../utilities/http/csrfToken', () => ({
  getCSRFToken: jest.fn(() => Promise.resolve(csrfToken)),
}));

/* global globalThis */
describe('Comment Subscription Utilities', () => {
  const articleID = 26; // Just a random article ID.

  beforeAll(() => {
    globalThis.fetch = fetch;
  });
  afterAll(() => {
    delete globalThis.fetch;
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('getCommentSubscriptionStatus', () => {
    it('should return a subscription status', async () => {
      const response = '{ "config": "all_comments" }';
      fetch.mockResponse(response);

      const subscriptionStatus = await getCommentSubscriptionStatus(articleID);

      expect(subscriptionStatus).toEqual(JSON.parse(response));
    });

    it('should return a friendly error message when it fails', async () => {
      fetch.mockResponse('<html>...some error page</html>');

      const subscriptionStatus = await getCommentSubscriptionStatus(articleID);

      expect(subscriptionStatus instanceof Error).toEqual(true);
      expect(subscriptionStatus.message).toEqual(
        'An error occurred, please try again',
      );
    });
  });

  describe('setCommentSubscriptionStatus', () => {
    it('should unsubscribe', async () => {
      fetch.mockResponse('false');

      const subscriptionStatusMessage = await setCommentSubscriptionStatus(
        articleID,
        'not_subscribed',
      );

      expect(subscriptionStatusMessage).toEqual(
        'You have been unsubscribed from comments for this post',
      );
    });

    it('should subscribe', async () => {
      fetch.mockResponse(true);

      const subscriptionStatusMessage = await setCommentSubscriptionStatus(
        articleID,
        'all_comments',
      );

      expect(subscriptionStatusMessage).toEqual(
        'You have been subscribed to all comments',
      );
    });

    it('should return a friendly error message if HTML is returned', async () => {
      fetch.mockResponse('<html><body>error</body></html>');

      const subscriptionStatusMessage = await setCommentSubscriptionStatus(
        articleID,
        'all_comments',
      );

      expect(subscriptionStatusMessage).toEqual(
        'An error occurred, please try again',
      );
    });

    it('should return a friendly error message if an error occurs', async () => {
      fetch.mockReject(() => new Error('oh no'));

      const subscriptionStatusMessage = await setCommentSubscriptionStatus(
        articleID,
        'all_comments',
      );

      expect(subscriptionStatusMessage).toEqual(
        'An error occurred, please try again',
      );
    });

    it('should return a friendly error message if an HTTP status object is returned', async () => {
      fetch.mockResponse('{"status":405,"error":"Method Not Allowed"}');

      const subscriptionStatusMessage = await setCommentSubscriptionStatus(
        articleID,
        'all_comments',
      );

      expect(subscriptionStatusMessage).toEqual(
        'An error occurred, please try again',
      );
    });
  });
});
