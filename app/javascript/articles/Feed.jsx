import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { useListNavigation } from '../shared/components/useListNavigation';
import { useKeyboardShortcuts } from '../shared/components/useKeyboardShortcuts';
import { insertInArrayIf } from '../../javascript/utilities/insertInArrayIf';

// Utility functions (assuming they are defined elsewhere)
const isJSON = (result) => result.value.headers?.get('content-type')?.includes('application/json');
const isHTML = (result) => result.value.headers?.get('content-type')?.includes('text/html');

export const Feed = ({ timeFrame, renderFeed, afterRender }) => {
  // User data and helper functions assumed to be available globally
  const { reading_list_ids = [] } = userData();
  const getCsrfToken = async () => { ... }; // implementation for getting CSRF token
  const sendFetch = (endpoint, data) => { ... }; // implementation for sending fetch requests

  const [bookmarkedFeedItems, setBookmarkedFeedItems] = useState(new Set(reading_list_ids));
  const [pinnedItem, setPinnedItem] = useState(null);
  const [imageItem, setimageItem] = useState(null);
  const [feedItems, setFeedItems] = useState([]);
  const [onError, setOnError] = useState(false);

  useEffect(() => {
    const fetchFeedItems = async (timeFrame = '', page = 1) => {
      const promises = [
        fetch(`/stories/feed/<span class="math-inline">\{timeFrame\}?page\=</span>{page}`, {
          method: 'GET',
          headers: {
            Accept: 'application/json',
            'X-CSRF-Token': await getCsrfToken(),
            'Content-Type': 'application/json',
          },
          credentials: 'same-origin',
        }),
        fetch('/billboards/feed_first'),
        fetch('/billboards/feed_second'),
        fetch('/billboards/feed_third'),
      ];

      const results = await Promise.allSettled(promises);
      const feedItems = [];
      for (const result of results) {
        if (result.status === 'fulfilled') {
          let resolvedValue;
          if (isJSON(result)) {
            resolvedValue = await result.value.json();
          } else if (isHTML(result)) {
            resolvedValue = await result.value.text();
          }
          feedItems.push(resolvedValue);
        } else {
          Honeybadger.notify(
            `failed to fetch some items on the home feed: ${result.reason}`,
          );
          feedItems.push(undefined); // maintain placeholder for display organization
        }
      }
      return feedItems;
    };

    const setPinnedPostItem = (pinnedPost, imagePost) => {
      // Only show pinned post on relevant feed (no timeframe selected)
      if (!pinnedPost || timeFrame !== '') return false;

      // Set pinned post if different from image post
      if (pinnedPost.id !== imagePost?.id) {
        setPinnedItem(pinnedPost);
        return true;
      }
      return false;
    };

    const organizeFeedItems = async () => {
      try {
        if (onError) setOnError(false);

        const fetchedItems = await fetchFeedItems(timeFrame);
        const [
          feedPosts,
          feedFirstBillboard,
          feedSecondBillboard,
          feedThirdBillboard,
        ] = fetchedItems;

        const imagePost = getImagePost(feedPosts);
        const pinnedPost = getPinnedPost(feedPosts);
        const podcastPost = getPodcastEpisodes(); // assumed to be implemented elsewhere

        const hasSetPinnedPost = setPinnedPostItem(pinnedPost, imagePost);
        const hasSetImagePostItem = setImagePostItem(imagePost);

        const updatedFeedPosts = updateFeedPosts(
          feedPosts,
          imagePost,
          pinnedPost,
        );

        // Organize feed items with pinned post, image post, podcasts, remaining stories, and billboards
        const organizedFeedItems = [
          ...insertInArrayIf(hasSetPinnedPost, pinnedPost),
          ...insertInArrayIf(hasSetImagePostItem, imagePost),
          ...insertInArrayIf(podcastPost.length > 0, podcastPost),
          ...updatedFeedPosts

