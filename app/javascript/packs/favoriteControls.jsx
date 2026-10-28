import { h, render } from 'preact';
import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';
import { checkUserLoggedIn } from '@utilities/checkUserLoggedIn';
import { globalFeatureFlagEnabled } from '@utilities/featureFlags';
import { FavoriteControl } from '../favoriteControl/FavoriteControl';

let latestUser = null;
let commentObserver = null;

function userSignature(user) {
  if (!user) return 'anon';
  return `${user.id}:${Boolean(user.community_leader)}:${
    user.favorite_allowance === null ? 'unlimited' : user.favorite_allowance
  }`;
}

export function initializeFavoriteControls(currentUser) {
  latestUser = currentUser;
  const sig = userSignature(currentUser);
  const nodes = document.querySelectorAll('[data-favorite-control]');

  for (const node of nodes) {
    if (
      node.dataset.initialized === 'true' &&
      node.dataset.userSignature === sig
    ) {
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

    const wrapper = node.closest('[data-gem-action-wrapper]');
    if (wrapper) {
      wrapper.classList.remove('community-leader-visible-block');
    }

    node.dataset.initialized = 'true';
    node.dataset.userSignature = sig;
  }
}

function observeCommentsContainer() {
  if (commentObserver) {
    commentObserver.disconnect();
    commentObserver = null;
  }
  const container = document.getElementById('comment-trees-container');
  if (!container || typeof MutationObserver === 'undefined') {
    return;
  }
  commentObserver = new MutationObserver(() => {
    initializeFavoriteControls(latestUser);
  });
  commentObserver.observe(container, { childList: true, subtree: true });
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
    observeCommentsContainer();
  });
}

window.addEventListener('forem:user-data-loaded', (event) => {
  if (!globalFeatureFlagEnabled('community_favorites')) {
    return;
  }
  const freshUser = event?.detail?.user;
  if (freshUser) {
    initializeFavoriteControls(freshUser);
    observeCommentsContainer();
  }
});

mount();

if (window.InstantClick) {
  window.InstantClick.on('change', () => {
    mount();
  });
}
