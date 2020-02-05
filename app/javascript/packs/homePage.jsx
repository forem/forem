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

import('../leftSidebar/TagsFollowed').then(({ TagsFollowed }) => {
  const user = userData();

  if (user === null) {
    return;
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

  render(
    <TagsFollowed tags={followedTags} />,
    document.getElementById('sidebar-nav-followed-tags-ctn'),
  );
});
