import { h, render } from 'preact';
import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';
import { checkUserLoggedIn } from '@utilities/checkUserLoggedIn';
import { globalFeatureFlagEnabled } from '@utilities/featureFlags';
import { FavoriteControl } from '../favoriteControl/FavoriteControl';

function initializeFavoriteControls(currentUser) {
  const nodes = document.querySelectorAll('[data-favorite-control]');

  for (const node of nodes) {
    if (node.dataset.initialized === 'true') {
      continue;
    }

    const {
      variant,
      favoritableType,
      favoritableId,
      favoritableUserId,
      favorited,
      favoritedByUserId,
      labelFavorite,
      labelFavorited,
      labelFavoritedByYou,
    } = node.dataset;

    render(
      <FavoriteControl
        currentUser={currentUser}
        variant={variant}
        favoritableType={favoritableType}
        favoritableId={favoritableId}
        favoritableUserId={favoritableUserId}
        favorited={favorited}
        favoritedByUserId={favoritedByUserId}
        labelFavorite={labelFavorite}
        labelFavorited={labelFavorited}
        labelFavoritedByYou={labelFavoritedByYou}
      />,
      node,
    );

    node.dataset.initialized = 'true';
  }
}

function mount() {
  if (!globalFeatureFlagEnabled('community_favorites')) {
    return;
  }

  // Visitors should still see the indicator on favorited content when not
  // logged in. Mount straight away instead of waiting for user data.
  if (!checkUserLoggedIn()) {
    initializeFavoriteControls(null);
    return;
  }

  getUserDataAndCsrfTokenSafely().then(({ currentUser }) => {
    initializeFavoriteControls(currentUser);
  });
}

mount();

window.InstantClick.on('change', () => {
  mount();
});
