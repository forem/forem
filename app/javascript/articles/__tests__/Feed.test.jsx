/* eslint-disable no-irregular-whitespace */
import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { Feed } from '../Feed';
import {
  feedPosts,
  firstBillboard,
  secondBillboard,
  thirdBillboard,
} from './utilities/feedUtilities';
import '../../../assets/javascripts/lib/xss';
import '../../../assets/javascripts/utilities/timeAgo';

global.fetch = fetch;

describe('<Feed /> component', () => {
  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());

    global.userData = async () => getUserData();
  });

  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
      reading_list_ids: [],
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

    it('should set the pinnedItem', async () => {
      await waitFor(() => {
        const lastCallback =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        const firstPinnedItem = feedPosts.find((o) => o.pinned === true);
        expect(lastCallback.pinnedItem).toEqual(firstPinnedItem);
      });
    });

    it.skip('should set the imageItem', async () => {});

    it.skip('should set the correct podcastEpisodes', async () => {
      // we can remove this
    });

    it.skip('should set the correct bookmarkedFeedItems', async () => {});

    it.skip('should set the correct bookmarkClick', async () => {});
  });

  // if pinned and featured are the same
  // pinned and featured should only appear once

  describe.skip('feedItem configuration', () => {
    it('should return the correct length of feedItems', () => {});

    it('should set the billboards in the correct placements within the feedItems', async () => {});

    it('should set the podcasts in the correct placement in the feedItems', async () => {});
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
