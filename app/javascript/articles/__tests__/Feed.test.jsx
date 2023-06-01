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

  describe('pinned and image posts are the same', () => {
    let callback;
    beforeAll(() => {
      fetch.mockResponseOnce(
        JSON.stringify(feedPostsWherePinnedAndImagePostsSame),
      );
      fetch.mockResponseOnce(firstBillboard);
      fetch.mockResponseOnce(secondBillboard);
      fetch.mockResponseOnce(thirdBillboard);

      callback = jest.fn();
      render(<Feed timeFrame="" renderFeed={callback} />);
    });

    it('should not set a pinned item', async () => {
      const lastCallback =
        callback.mock.calls[callback.mock.calls.length - 1][0];
      const postAndImageItem = feedPostsWherePinnedAndImagePostsSame.find(
        (post) => post.main_image !== null && post.pinned === true,
      );

      expect(lastCallback.pinnedItem).toEqual(null);
      expect(lastCallback.imageItem).toEqual(postAndImageItem);
      expect(lastCallback.feedItems[1]).toEqual(postAndImageItem);
      expect(lastCallback.feedItems[2]).not.toEqual(postAndImageItem);
    });
  });

  //   test that the callback is called
  describe('pinnedItem, imageItem, bookmarkedFeedItems and bookmarkClick', () => {
    let callback;
    beforeAll(() => {
      fetch.mockResponseOnce(JSON.stringify(feedPosts));
      fetch.mockResponseOnce(firstBillboard);
      fetch.mockResponseOnce(secondBillboard);
      fetch.mockResponseOnce(thirdBillboard);

      callback = jest.fn();
      render(<Feed timeFrame="" renderFeed={callback} />);
    });

    it.skip('should set the correct bookmarkedFeedItems', async () => {});

    it.skip('should set the correct bookmarkClick', async () => {});
  });

  // if pinned and featured are the same
  // pinned and featured should only appear once

  describe('feedItem configuration', () => {
    let callback;
    beforeAll(() => {
      fetch.mockResponseOnce(JSON.stringify(feedPosts));
      fetch.mockResponseOnce(firstBillboard);
      fetch.mockResponseOnce(secondBillboard);
      fetch.mockResponseOnce(thirdBillboard);

      callback = jest.fn();
      render(<Feed timeFrame="" renderFeed={callback} />);
    });

    it('should return the correct length of feedItems', async () => {
      await waitFor(() => {
        const lastCallback =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        expect(lastCallback.feedItems.length).toEqual(13);
      });
    });

    it('should set the pinnedItem and place it correctly in the feed', async () => {
      await waitFor(() => {
        const lastCallback =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        const firstPinnedItem = feedPosts.find((o) => o.pinned === true);
        expect(lastCallback.pinnedItem).toEqual(firstPinnedItem);
        expect(lastCallback.feedItems[1]).toEqual(firstPinnedItem);
      });
    });

    it('should set the imageItem and place it correctly in the feed', async () => {
      await waitFor(() => {
        const lastCallback =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        const firstImageItem = feedPosts.find(
          (post) => post.main_image !== null,
        );
        expect(lastCallback.imageItem).toEqual(firstImageItem);
        expect(lastCallback.feedItems[2]).toEqual(firstImageItem);
      });
    });

    it('should set the billboards in the correct placements within the feedItems', async () => {
      await waitFor(() => {
        const lastCallback =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        expect(lastCallback.feedItems[0]).toEqual(firstBillboard);
        expect(lastCallback.feedItems[3]).toEqual(secondBillboard);
      });
    });

    it('should set the podcasts in the correct placement in the feedItems', async () => {
      await waitFor(() => {
        const lastCallback =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        expect(lastCallback.feedItems[4]).toEqual(podcastEpisodes);
      });
    });
  });

  describe.skip('feedItem configuration alternate', () => {
    it('should return the correct length of feedItems', () => {});

    it('should set the billboards in the correct placements within the feedItems', async () => {});

    it('should set the podcasts in the correct placement in the feedItems', async () => {});
  });

  it.skip('should return the organized feed items', async () => {
    // const callback = jest.fn();
    // fetch.mockResponseOnce(fakeTagsResponse);
    // const { container } = render(
    //   <Feed timeFrame='' renderFeed={callback} />
    // );
    // await waitFor(() =>
    //  {
    //     expect(callback).toHaveBeenCalled();
    //     const lastCallback = callback.mock.calls[callback.mock.calls.length - 1]
    //     console.log("last callback", lastCallback)
    //     return expect(object).toBe({
    //       html: expect.any(String)
    //     });
    //   }
    // //  expect(array).toMatchObject(['billboard 1', expect.any(Object), 'sdfsdf'])
    // )
  });
});
