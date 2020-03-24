import { h, render } from 'preact';

/* global userData */

// This logic is similar to that in initScrolling.js.erb
// that prevents the classic Algolia scrolling for the front page.
const frontPageFeedPathNames = new Map([
  ['/', ''],
  ['/top/week', 'week'],
  ['/top/month', 'month'],
  ['/top/year', 'year'],
  ['/top/infinity', 'infinity'],
  ['/latest', 'latest'],
]);

function toggleListingsMinimization() {
  if (document.body.classList.contains('config_minimize_newest_listings')) {
    // Un-minimize
    localStorage.setItem('config_minimize_newest_listings', 'no');
    document.body.classList.remove('config_minimize_newest_listings');
  } else {
    // Minimize
    localStorage.setItem('config_minimize_newest_listings', 'yes');
    document.body.classList.add('config_minimize_newest_listings');
  }
}

const sidebarListingsMinimizeButton = document.getElementById(
  'sidebar-listings-widget-minimize-button',
);
if (sidebarListingsMinimizeButton) {
  sidebarListingsMinimizeButton.addEventListener(
    'click',
    toggleListingsMinimization,
  );
}

/**
 * Renders tags followed in the left side bar of the homepage.
 *
 * @param {HTMLElement} tagsFollowedContainer DOM element to render tags followed.
 * @param {object} user The currently logged on user, null if not logged on.
 */

  function renderTagsFollowed(tagsFollowedContainer, user = userData()) {
    if (user === null || document.getElementById('followed-tags-wrapper')) {
      return;
    }
  
    // Only render if a user is logged on.
    import('../leftSidebar/TagsFollowed').then(({ TagsFollowed }) => {
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
  
      render(<TagsFollowed tags={followedTags} />, tagsFollowedContainer, tagsFollowedContainer.firstElementChild);
    });
  }  

const feedTimeFrame = frontPageFeedPathNames.get(window.location.pathname);


if (!document.getElementById('featured-story-marker')) {
  let waitingForDataLoad = setInterval(function dataLoadedCheck() {
    const { user = null, userStatus } = document.body.dataset;
    if (userStatus === 'logged-out') {
      return;
    }
  
    if (userStatus === 'logged-in' && user !== null) {
      clearTimeout(waitingForDataLoad);
  
      import('./homePageFeed').then(({ renderFeed }) => {
        // We have user data, render followed tags.
        renderFeed(feedTimeFrame);
  
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
  
          renderFeed(changedFeedTimeFrame);
        });
      });
      renderTagsFollowed(document.getElementById('sidebar-nav-followed-tags'));
      return;
    }
  }, 2);  
}


InstantClick.on('receive', (address, body, title) => {
  if (document.body.dataset.userStatus !== 'logged-in') {
    // Nothing to do, the user is not logged on.
    return false;
  }

  const tagsFollowedContainer = body.querySelector(
    '#sidebar-nav-followed-tags',
  );

  if (!tagsFollowedContainer) {
    // Not on the homepage, so nothing to do.
    return false;
  }

  renderTagsFollowed(tagsFollowedContainer);

  return {
    body,
    title,
  };
});
InstantClick.init();
