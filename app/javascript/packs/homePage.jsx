import { h, render } from 'preact';

/* global userData */

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
  if (user === null) {
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

    render(<TagsFollowed tags={followedTags} />, tagsFollowedContainer);
  });
}

let waitingForDataLoad = setTimeout(function dataLoadedCheck() {
  const { user = null, userStatus } = document.body.dataset;

  if (userStatus === 'logged-out') {
    // Nothing to do, the user is not logged on.
    return;
  }

  if (userStatus === 'logged-in' && user !== null) {
    // We have user data, render followed tags.
    clearTimeout(waitingForDataLoad);
    renderTagsFollowed(document.getElementById('sidebar-nav-followed-tags'));
    return;
  }

  // No user data yet for the logged on user, poll once more.
  waitingForDataLoad = setTimeout(dataLoadedCheck, 40);
}, 40);

InstantClick.on('receive', (_url, body, title) => {
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
