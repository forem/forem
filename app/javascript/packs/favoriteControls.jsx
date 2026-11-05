import { h, render } from 'preact';
import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';
import { checkUserLoggedIn } from '@utilities/checkUserLoggedIn';
import { globalFeatureFlagEnabled } from '@utilities/featureFlags';
import { FavoriteControl } from '../favoriteControl/FavoriteControl';

/**
 * Mounts FavoriteControl instances onto uninitialized `[data-favorite-control]` nodes,
 * skipping Preact rendering on unfavorited nodes when the viewer cannot favorite them.
 * @param {Object|null} currentUser The signed-in user object, or null when signed out.
 */
function initializeFavoriteControls(currentUser) {
  const nodes = document.querySelectorAll('[data-favorite-control]');
  const userId = currentUser?.id ?? null;
  const canSeeControl =
    currentUser?.community_leader === true ||
    (currentUser?.favorite_allowance != null &&
      currentUser.favorite_allowance > 0);

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
      confirmTitle,
      confirmBody,
      confirmSubmit,
      confirmCancel,
      modalTitle,
      modalBody,
      modalRemainingZero,
      modalRemainingOne,
      modalRemainingOther,
      modalRemainingUnlimited,
      modalClose,
      modalExhaustedTitle,
      modalExhaustedBody,
      modalExhaustedClose,
    } = node.dataset;

    const isFavorited = favorited === 'true';
    const isOwnContent =
      userId != null && Number(favoritableUserId) === userId;

    if (!isFavorited && (!canSeeControl || isOwnContent)) {
      if (node.children.length > 0) {
        node.innerHTML = '';
      }
      node.dataset.initialized = 'true';
      continue;
    }

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
        confirmTitle={confirmTitle}
        confirmBody={confirmBody}
        confirmSubmit={confirmSubmit}
        confirmCancel={confirmCancel}
        modalTitle={modalTitle}
        modalBody={modalBody}
        modalRemainingZero={modalRemainingZero}
        modalRemainingOne={modalRemainingOne}
        modalRemainingOther={modalRemainingOther}
        modalRemainingUnlimited={modalRemainingUnlimited}
        modalClose={modalClose}
        modalExhaustedTitle={modalExhaustedTitle}
        modalExhaustedBody={modalExhaustedBody}
        modalExhaustedClose={modalExhaustedClose}
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

if (!window.__favoriteControlsListenerRegistered) {
  window.__favoriteControlsListenerRegistered = true;
  window.InstantClick?.on('change', () => {
    mount();
  });
}
