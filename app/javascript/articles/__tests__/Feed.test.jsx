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

    it('should set the imageItem', async () => {
      await waitFor(() => {
        const lastCallback =
          callback.mock.calls[callback.mock.calls.length - 1][0];
        const firstImageItem = feedPosts.find(
          (post) => post.main_image !== null,
        );
        expect(lastCallback.imageItem).toEqual(firstImageItem);
      });
    });

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
