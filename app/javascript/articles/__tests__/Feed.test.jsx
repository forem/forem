/* eslint-disable no-irregular-whitespace */
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
