import { h, render } from 'preact';
import ahoy from 'ahoy.js';
import { TagsFollowed } from '../leftSidebar/TagsFollowed';
import {
  observeBillboards,
  initializeBillboardVisibility,
} from '../packs/billboardAfterRenderActions';
import { observeFeedElements } from '../packs/feedEvents';
import { setupBillboardInteractivity } from '@utilities/billboardInteractivity';
import { trackCreateAccountClicks } from '@utilities/ahoy/trackEvents';

/* global userData */
// This logic is similar to that in initScrolling.js.erb
const frontPageFeedPathNames = new Map([
  ['/', ''],
  ['/top/week', 'week'],
  ['/top/month', 'month'],
  ['/top/year', 'year'],
  ['/top/infinity', 'infinity'],
  ['/latest', 'latest'],
]);

/**
 * Renders tags followed in the left side bar of the homepage.
 *
 * @param {HTMLElement} tagsFollowedContainer DOM element to render tags followed.
 * @param {object} user The currently logged on user, null if not logged on.
 */

function renderTagsFollowed(user = userData()) {
  const tagsFollowedContainer = document.getElementById(
    'sidebar-nav-followed-tags',
  );
  if (user === null || !tagsFollowedContainer) {
    // Return and do not render if the user is not logged in
    // or if this is not the home page.
    return false;
  }

  const { followed_tags } = user; // eslint-disable-line camelcase
  const followedTags = JSON.parse(followed_tags);

  // This should be done server-side potentially
  // sort tags by descending weight, descending popularity and name
  followedTags.sort((tagA, tagB) => {
    return (
      tagB.points - tagA.points ||
      tagB.hotness_score - tagA.hotness_score ||
      tagA.name.localeCompare(tagB.name)
    );
  });

  render(<TagsFollowed tags={followedTags} />, tagsFollowedContainer);
  trackTagCogIconClicks();
}

// Temporary Ahoy Stats for usage reports
function trackTagCogIconClicks() {
  document
    .getElementById('tag-priority-link')
    ?.addEventListener('click', () => {
      ahoy.track('Tag settings cog icon click');
    });
}

function removeLocalePath(pathname) {
  return pathname.replace(/^\/locale\/[a-zA-Z-]+\/?/, '/');
}

function renderSidebar() {
  const sidebarContainer = document.getElementById('sidebar-wrapper-right');
  const pathname = removeLocalePath(window.location.pathname);

  // If the screen's width is less than 640 we don't need this extra data.
  if (
    sidebarContainer &&
    screen.width >= 640 &&
    (pathname === '/' || pathname === '/latest' || pathname.includes('/top/'))
  ) {
    window
      .fetch('/sidebars/home')
      .then((res) => res.text())
      .then((response) => {
        sidebarContainer.innerHTML = response;
        setupBillboardInteractivity();
      });
  }
}

const feedTimeFrame = frontPageFeedPathNames.get(window.location.pathname);

if (document.getElementById('sidebar-nav-followed-tags')) {
  const waitingForDataLoad = setInterval(() => {
    const { user = null, userStatus } = document.body.dataset;
    if (userStatus === 'logged-out') {
      return;
    }

    if (userStatus === 'logged-in' && user !== null) {
      clearInterval(waitingForDataLoad);
      if (document.getElementById('rendered-article-feed')) {
        return;
      }
      import('./homePageFeed').then(({ renderFeed }) => {
        const callback = () => {
          initializeBillboardVisibility();
          observeBillboards();
          setupBillboardInteractivity();
          observeFeedElements();
        };

        renderFeed(feedTimeFrame, callback);

        InstantClick.on('change', () => {
          const { userStatus: currentUserStatus } = document.body.dataset;

          if (currentUserStatus === 'logged-out') {
            return;
          }

          const url = new URL(window.location);
          const changedFeedTimeFrame = frontPageFeedPathNames.get(url.pathname);

          if (!frontPageFeedPathNames.has(url.pathname)) {
            return;
          }

          const callback = () => {
            initializeBillboardVisibility();
            observeBillboards();
            setupBillboardInteractivity();
            observeFeedElements();
          };

          renderFeed(changedFeedTimeFrame, callback);
        });
      });

      renderTagsFollowed();
      renderSidebar();
    }
  }, 2);
}

InstantClick.on('change', () => {
  if (document.body.dataset.userStatus !== 'logged-in') {
    // Nothing to do, the user is not logged on.
    return false;
  }

  renderTagsFollowed();
  renderSidebar();
});
InstantClick.init();

trackCreateAccountClicks('sidebar-wrapper-left');
