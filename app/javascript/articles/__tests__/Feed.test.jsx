/* eslint-disable no-irregular-whitespace */
import { webcrypto } from 'crypto';
import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { Feed } from '../Feed';
import {
  feedPosts,
  feedPostsWherePinnedAndImagePostsSame,
  firstBillboard,
  secondBillboard,
  thirdBillboard,
  podcastEpisodes,
} from './utilities/feedUtilities';
import '../../../assets/javascripts/lib/xss';
import '../../../assets/javascripts/utilities/timeAgo';

global.fetch = fetch;

describe('<Feed /> component', () => {
  const getUserData = () => {
    return {
      followed_tag_names: ['javascript'],
      followed_podcast_ids: [1], //should we make this dynamic
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
      reading_list_ids: [],
    };
  };

  beforeAll(() => {
    global.userData = jest.fn(() => getUserData());
    document.body.setAttribute('data-user', JSON.stringify(getUserData()));

    const node = document.createElement('div');
    node.setAttribute('id', 'followed-podcasts');
    node.setAttribute('data-episodes', JSON.stringify(podcastEpisodes));
    document.body.appendChild(node);
  });

  describe('home-feed visibility acknowledgements', () => {
    let visibility;
    let originalCrypto;
    beforeEach(() => {
      originalCrypto = window.crypto;
      Object.defineProperty(window, 'crypto', { configurable: true, value: webcrypto });
      visibility = jest.spyOn(document, 'visibilityState', 'get').mockReturnValue('visible');
      window.csrfToken = 'csrf-test';
      fetch.resetMocks();
      fetch.mockResponse((request) => {
        if (request.url === '/feed_config_visits') {
          return Promise.resolve({ body: '', init: { headers: { 'X-Feed-Visit-Wait': '1800' } } });
        }
        if (request.url.startsWith('/stories/feed/')) {
          return Promise.resolve({
            body: JSON.stringify(feedPosts),
            init: { headers: { 'content-type': 'application/json', 'X-Feed-Visit-Token': 'signed-proof' } },
          });
        }
        return Promise.resolve({ body: '', init: { headers: { 'content-type': 'text/html' } } });
      });
    });

    afterEach(() => {
      jest.restoreAllMocks();
      Object.defineProperty(window, 'crypto', { configurable: true, value: originalCrypto });
      localStorage.removeItem('current_feed');
      delete window.csrfToken;
    });

    it.each([
      ['visible', '', 'discover', true],
      ['hidden', '', 'discover', false],
      ['visible', 'latest', 'discover', false],
      ['visible', '', 'following', false],
      ['visible', '', 'curated', false],
    ])(
      'acknowledges only visible rendered Discover content (%s, %s, %s)',
      async (state, timeFrame, feedType, expected) => {
        visibility.mockReturnValue(state);
        localStorage.setItem('current_feed', feedType);
        const callback = jest.fn(() => null);
        render(<Feed timeFrame={timeFrame} renderFeed={callback} />);
        await waitFor(() => expect(callback).toHaveBeenLastCalledWith(expect.objectContaining({ isLoading: false })));
        await waitFor(() => {
          const visits = fetch.mock.calls.filter(([url]) => url === '/feed_config_visits');
          expect(visits).toHaveLength(expected ? 1 : 0);
        });
        expect(fetch.mock.calls[0][1].headers['X-Feed-Visit']).toBeUndefined();

        if (state === 'hidden') {
          visibility.mockReturnValue('visible');
          document.dispatchEvent(new Event('visibilitychange'));
          await waitFor(() => expect(fetch.mock.calls.filter(([url]) => url === '/feed_config_visits')).toHaveLength(1));
        }
      },
    );

    it('does not acknowledge empty feed responses even if they include a token', async () => {
      fetch.mockResponseOnce('[]', {
        headers: { 'content-type': 'application/json', 'X-Feed-Visit-Token': 'signed-proof' },
      });
      const callback = jest.fn(() => null);
      render(<Feed timeFrame="" renderFeed={callback} />);
      await waitFor(() => expect(callback).toHaveBeenLastCalledWith(expect.objectContaining({ isLoading: false })));
      expect(fetch.mock.calls.some(([url]) => url === '/feed_config_visits')).toBe(false);
    });

    it('shows a failed feed once without acknowledging it or creating a request loop', async () => {
      fetch.mockResponseOnce(JSON.stringify(feedPosts), {
        status: 503,
        headers: { 'content-type': 'application/json', 'X-Feed-Visit-Token': 'signed-proof' },
      });
      const { getByText } = render(<Feed timeFrame="" renderFeed={() => null} />);
      await waitFor(() => expect(getByText('There was a problem fetching your feed.')).toBeInTheDocument());
      await new Promise((resolve) => setTimeout(resolve, 100));
      expect(fetch.mock.calls.filter(([url]) => url.startsWith('/stories/feed/'))).toHaveLength(1);
      expect(fetch.mock.calls.some(([url]) => url === '/feed_config_visits')).toBe(false);
    });

    it('ignores a stale Discover response after switching to another feed', async () => {
      let finishInitial;
      const feedResponse = {
        ok: true,
        headers: { get: (name) => name === 'content-type' ? 'application/json' : 'old-proof' },
        json: async () => JSON.parse(JSON.stringify(feedPosts)),
      };
      fetch.mockImplementation((url) => {
        if (url.startsWith('/stories/feed/latest')) return Promise.resolve(feedResponse);
        if (url.startsWith('/stories/feed/')) {
          return new Promise((resolve) => { finishInitial = () => resolve(feedResponse); });
        }
        return Promise.resolve({ headers: { get: () => 'text/html' }, text: async () => '' });
      });
      const callback = jest.fn(() => null);
      const { container } = render(<Feed timeFrame="" renderFeed={callback} />);
      await waitFor(() => expect(finishInitial).toBeDefined());
      render(<Feed timeFrame="latest" renderFeed={callback} />, { container });
      await waitFor(() => expect(callback).toHaveBeenLastCalledWith(expect.objectContaining({ isLoading: false })));
      finishInitial();
      await new Promise((resolve) => setTimeout(resolve, 100));
      expect(fetch.mock.calls.some(([url]) => url === '/feed_config_visits')).toBe(false);
    });

    it('does not acknowledge the previous feed while transitioning away from displayed Discover content', async () => {
      const callback = jest.fn(() => null);
      const { container } = render(<Feed timeFrame="" renderFeed={callback} />);
      await waitFor(() => expect(fetch.mock.calls.filter(([url]) => url === '/feed_config_visits')).toHaveLength(1));
      render(<Feed timeFrame="latest" renderFeed={callback} />, { container });
      await waitFor(() => expect(callback).toHaveBeenLastCalledWith(expect.objectContaining({ isLoading: false })));
      await new Promise((resolve) => setTimeout(resolve, 100));
      expect(fetch.mock.calls.filter(([url]) => url === '/feed_config_visits')).toHaveLength(1);
    });
  });

  describe('feedItem organization', () => {
    let callback;
    beforeAll(() => {
      fetch.mockResponseOnce(JSON.stringify(feedPosts), {
        headers: { 'content-type': 'application/json' },
      });
      fetch.mockResponseOnce(firstBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(secondBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(thirdBillboard, {
        headers: { 'content-type': 'text/html' },
      });

      callback = jest.fn();
      render(<Feed timeFrame="" renderFeed={callback} />);
    });

    it('should return the correct length of feedItems', async () => {
      await waitFor(() => {
        const lastCallbackResult =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        expect(lastCallbackResult.feedItems.length).toEqual(14);
      });
    });

    it('should set the pinnedItem and place it correctly in the feed', async () => {
      await waitFor(() => {
        const lastCallbackResult =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        const firstPinnedItem = feedPosts.find((o) => o.pinned === true);
        expect(lastCallbackResult.pinnedItem).toEqual(firstPinnedItem);
        expect(lastCallbackResult.feedItems[1]).toEqual(firstPinnedItem);
      });
    });

    it('should set the imageItem and place it correctly in the feed', async () => {
      await waitFor(() => {
        const lastCallbackResult =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        const firstImageItem = feedPosts.find(
          (post) => post.main_image !== null,
        );
        expect(lastCallbackResult.imageItem).toEqual(firstImageItem);
        expect(lastCallbackResult.feedItems[2]).toEqual(firstImageItem);
      });
    });

    it('should place the billboards correctly within the feedItems', async () => {
      await waitFor(() => {
        const lastCallbackResult =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        expect(lastCallbackResult.feedItems[0]).toEqual(firstBillboard);
        expect(lastCallbackResult.feedItems[3]).toEqual(secondBillboard);
        expect(lastCallbackResult.feedItems[9]).toEqual(thirdBillboard);
      });
    });

    it('should place the podcasts correctly within feedItems', async () => {
      await waitFor(() => {
        const lastCallbackResult =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        expect(lastCallbackResult.feedItems[4]).toEqual(podcastEpisodes);
      });
    });
  });

  describe('when pinned and image posts are the same', () => {
    let callback;
    beforeAll(() => {
      fetch.mockResponseOnce(
        JSON.stringify(feedPostsWherePinnedAndImagePostsSame),
        { headers: { 'content-type': 'application/json' } },
      );
      fetch.mockResponseOnce(firstBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(secondBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(thirdBillboard, {
        headers: { 'content-type': 'text/html' },
      });

      callback = jest.fn();
      render(<Feed timeFrame="" renderFeed={callback} />);
    });

    it('should not set a pinned item', async () => {
      const lastCallbackResult =
        callback.mock.calls[callback.mock.calls.length - 1][0];
      const postAndImageItem = feedPostsWherePinnedAndImagePostsSame.find(
        (post) => post.main_image !== null && post.pinned === true,
      );

      expect(lastCallbackResult.pinnedItem).toEqual(null);
      expect(lastCallbackResult.imageItem).toEqual(postAndImageItem);
      expect(lastCallbackResult.feedItems[1]).toEqual(postAndImageItem);
      expect(lastCallbackResult.feedItems[2]).not.toEqual(postAndImageItem);
    });
  });

  describe("when the timeframe prop is 'latest'", () => {
    let callback;
    beforeAll(() => {
      fetch.mockResponseOnce(JSON.stringify(feedPosts), {
        headers: { 'content-type': 'application/json' },
      });
      fetch.mockResponseOnce(firstBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(secondBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(thirdBillboard, {
        headers: { 'content-type': 'text/html' },
      });

      callback = jest.fn();
      render(<Feed timeFrame="latest" renderFeed={callback} />);
    });

    it('should not set the pinned items', async () => {
      const lastCallbackResult =
        callback.mock.calls[callback.mock.calls.length - 1][0];
      expect(lastCallbackResult.pinnedItem).toEqual(null);
    });

    it('should return the correct length of feedItems (by excluding pinned item)', async () => {
      await waitFor(() => {
        const lastCallbackResult =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        expect(lastCallbackResult.feedItems.length).toEqual(13);
      });
    });
  });

  describe("when we there isn't all three billboards on the home feed", () => {
    describe("when there isn't a feed_second billboard", () => {
      let callback;
      beforeAll(() => {
        fetch.mockResponseOnce(JSON.stringify(feedPosts), {
          headers: { 'content-type': 'application/json' },
        });
        fetch.mockResponseOnce(firstBillboard, {
          headers: { 'content-type': 'text/html' },
        });
        fetch.mockResponseOnce(undefined);
        fetch.mockResponseOnce(thirdBillboard, {
          headers: { 'content-type': 'text/html' },
        });

        callback = jest.fn();
        render(<Feed timeFrame="" renderFeed={callback} />);
      });

      it('should return the correct length of feedItems', async () => {
        await waitFor(() => {
          const lastCallbackResult =
            callback.mock.calls[callback.mock.calls.length - 1][0];
          expect(lastCallbackResult.feedItems.length).toEqual(13);
        });
      });

      it('should still amend the organization of the feedItems correctly', async () => {
        await waitFor(() => {
          const lastCallbackResult =
            callback.mock.calls[callback.mock.calls.length - 1][0];
          expect(lastCallbackResult.feedItems[0]).toEqual(firstBillboard);
          // there is no second billboard so podcasts get rendered in 4th place
          expect(lastCallbackResult.feedItems[3]).toEqual(podcastEpisodes);
          expect(lastCallbackResult.feedItems[8]).toEqual(thirdBillboard);
        });
      });
    });

    describe("when there isn't a feed_first or feed_second billboard", () => {
      let callback;
      beforeAll(() => {
        fetch.mockResponseOnce(JSON.stringify(feedPosts), {
          headers: { 'content-type': 'application/json' },
        });
        fetch.mockResponseOnce(undefined);
        fetch.mockResponseOnce(undefined);
        fetch.mockResponseOnce(thirdBillboard, {
          headers: { 'content-type': 'text/html' },
        });

        callback = jest.fn();
        render(<Feed timeFrame="" renderFeed={callback} />);
      });

      it('should return the correct length of feedItems', async () => {
        await waitFor(() => {
          const lastCallbackResult =
            callback.mock.calls[callback.mock.calls.length - 1][0];
          expect(lastCallbackResult.feedItems.length).toEqual(12);
        });
      });

      it('should still amend the organization of the feedItems correctly', async () => {
        await waitFor(() => {
          const lastCallbackResult =
            callback.mock.calls[callback.mock.calls.length - 1][0];

          const pinnedItem = feedPosts.find((o) => o.pinned === true);
          // there is no first billboard
          expect(lastCallbackResult.feedItems[0]).toEqual(pinnedItem);
          // there is no second billboard so podcasts get rendered in 3rd place
          expect(lastCallbackResult.feedItems[2]).toEqual(podcastEpisodes);
          expect(lastCallbackResult.feedItems[7]).toEqual(thirdBillboard);
        });
      });
    });

    describe('when items that we fetch for the feed throw an error', () => {
      const callback = jest.fn();

      beforeAll(() => {
        global.Honeybadger = { notify: jest.fn() };

        fetch.mockResponseOnce(JSON.stringify(feedPosts), {
          headers: { 'content-type': 'application/json' },
        });
        fetch.mockRejectOnce();
        fetch.mockRejectOnce();
        fetch.mockResponseOnce(thirdBillboard, {
          headers: { 'content-type': 'text/html' },
        });
        render(<Feed timeFrame="" renderFeed={callback} />);
      });

      it('should render and return the other feedItems', async () => {
        await waitFor(() => {
          const lastCallbackResult =
            callback.mock.calls[callback.mock.calls.length - 1][0];
          expect(lastCallbackResult.feedItems.length).toEqual(12);
        });
      });

      it('should organize the feedItems correctly', async () => {
        await waitFor(() => {
          const lastCallbackResult =
            callback.mock.calls[callback.mock.calls.length - 1][0];

          const pinnedItem = feedPosts.find((o) => o.pinned === true);
          // we will not be rendering the first billboard since it errored
          expect(lastCallbackResult.feedItems[0]).toEqual(pinnedItem);
          // we will not be rendering the second billboard since it errored
          // so podcasts get rendered in 3rd place
          expect(lastCallbackResult.feedItems[2]).toEqual(podcastEpisodes);
          expect(lastCallbackResult.feedItems[7]).toEqual(thirdBillboard);
        });
      });
    });
  });

  describe('afterRender callback across tab navigation', () => {
    beforeEach(() => {
      fetch.resetMocks();
    });

    it('invokes afterRender on initial load and again when returning from a tab where the billboard disappeared', async () => {
      const afterRender = jest.fn();
      const renderFeed = jest.fn(({ feedItems, isLoading }) =>
        isLoading ? (
          <div id="test-feed-loading" />
        ) : (
          <div id="test-feed-container">
            {feedItems.map((item, idx) =>
              typeof item === 'string' ? (
                <div
                  key={`billboard-${idx}`}
                  dangerouslySetInnerHTML={{ __html: item }}
                />
              ) : (
                <div key={item.id}>{item.title}</div>
              ),
            )}
          </div>
        ),
      );

      // 1. Initial load on Discover tab (timeFrame="")
      fetch.mockResponseOnce(JSON.stringify(feedPosts), {
        headers: { 'content-type': 'application/json' },
      });
      fetch.mockResponseOnce(firstBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(secondBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(thirdBillboard, {
        headers: { 'content-type': 'text/html' },
      });

      const { container } = render(
        <Feed
          timeFrame=""
          renderFeed={renderFeed}
          afterRender={afterRender}
        />,
      );

      await waitFor(() => {
        expect(afterRender).toHaveBeenCalledTimes(1);
      });

      // 2. Switch to a tab with no results (billboard disappears)
      fetch.mockResponseOnce(JSON.stringify([]), {
        headers: { 'content-type': 'application/json' },
      });
      fetch.mockResponseOnce('', {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce('', {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce('', {
        headers: { 'content-type': 'text/html' },
      });

      render(
        <Feed
          timeFrame="latest"
          renderFeed={renderFeed}
          afterRender={afterRender}
        />,
        { container },
      );

      await waitFor(() => {
        expect(
          document.getElementById('test-feed-container')?.children.length,
        ).toBe(0);
      });
      expect(afterRender).toHaveBeenCalledTimes(1);

      // 3. Switch back to Discover tab (billboard comes back, must re-trigger afterRender so scripts execute)
      fetch.mockResponseOnce(JSON.stringify(feedPosts), {
        headers: { 'content-type': 'application/json' },
      });
      fetch.mockResponseOnce(firstBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(secondBillboard, {
        headers: { 'content-type': 'text/html' },
      });
      fetch.mockResponseOnce(thirdBillboard, {
        headers: { 'content-type': 'text/html' },
      });

      render(
        <Feed
          timeFrame=""
          renderFeed={renderFeed}
          afterRender={afterRender}
        />,
        { container },
      );

      await waitFor(() => {
        expect(afterRender).toHaveBeenCalledTimes(2);
      });
      expect(
        document.getElementById('test-feed-container').textContent,
      ).toContain('billboard one');
    });
  });
});
