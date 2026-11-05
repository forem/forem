import { getUserDataAndCsrfTokenSafely } from '@utilities/getUserDataAndCsrfToken';

/* global showLoginModal, browserStoreCache */

// This Pack file has some dependencies for it to function accurately:
// Copy and paste the Follow and Hide button snippets from a tag card.
// An example can be found in app/views/tags/index.html.erb
// The tag card needs to contain a class .js-tag-card elements,
// with data attributes for the tag-id and name.
// The follow button and the hide button need to contain classes
// js-follow-tag-button and/or js-hide-tag-button respectively.

let snackTimeoutId = null;

/**
 * Displays a temporary snackbar toast inside `#snack-zone`.
 * @param {string} message The message to display in the snackbar.
 */
function showTagSnackbar(message) {
  const snackZone = document.getElementById('snack-zone');
  if (!snackZone) {
    return;
  }

  if (snackTimeoutId) {
    clearTimeout(snackTimeoutId);
    snackTimeoutId = null;
  }

  snackZone.textContent = '';

  const wrapper = document.createElement('div');
  wrapper.className = 'crayons-snackbar';

  const item = document.createElement('div');
  item.className = 'crayons-snackbar__item flex';
  item.dataset.testid = 'snackbar';

  const body = document.createElement('div');
  body.className = 'crayons-snackbar__body';
  body.setAttribute('role', 'alert');
  body.textContent = message;

  const actions = document.createElement('div');
  actions.className = 'crayons-snackbar__actions';

  const dismissBtn = document.createElement('button');
  dismissBtn.type = 'button';
  dismissBtn.className =
    'crayons-btn crayons-btn--ghost-success crayons-btn--inverted';
  dismissBtn.textContent = 'Dismiss';

  const dismiss = () => {
    if (snackTimeoutId) {
      clearTimeout(snackTimeoutId);
      snackTimeoutId = null;
    }
    wrapper.className = 'hidden';
    wrapper.textContent = '';
  };

  dismissBtn.addEventListener('click', dismiss);
  actions.appendChild(dismissBtn);
  item.appendChild(body);
  item.appendChild(actions);
  wrapper.appendChild(item);
  snackZone.appendChild(wrapper);

  snackTimeoutId = setTimeout(dismiss, 2000);
}

/**
 * Sends a POST request to `/follows` to update a tag's follow or hide status.
 * @param {Object} params
 * @returns {Promise<Response>}
 */
function postFollowItem({ id, following, hidden }) {
  return fetch('/follows', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      followable_type: 'Tag',
      followable_id: id,
      verb: `${following ? '' : 'un'}follow`,
      explicit_points: hidden ? -1 : 1,
    }),
    credentials: 'same-origin',
  });
}

/**
 * Renders and wires up the Follow and Hide button group inside a tag card's action container,
 * preserving any sibling elements such as a tag badge image.
 * @param {HTMLElement} container The `#tag-buttons-<id>` element.
 * @param {Object} options Tag metadata and initial follow/hide state.
 */
export function mountTagButtons(
  container,
  { id, name, isFollowing, isHidden },
) {
  if (!container) {
    return;
  }

  let following = Boolean(isFollowing);
  let hidden = Boolean(isHidden);

  const renderButtons = (activeAction = null) => {
    const group = document.createElement('div');
    group.className = 'flex gap-2';
    let nextFollowBtn = null;

    if (!hidden) {
      const followButtonLabel = following ? 'Following' : 'Follow';
      const followBtn = document.createElement('button');
      followBtn.type = 'button';
      followBtn.className = following
        ? 'crayons-btn crayons-btn--outlined'
        : 'c-btn c-btn--primary';
      followBtn.setAttribute('aria-pressed', String(following));
      followBtn.setAttribute('aria-label', `${followButtonLabel} tag: ${name}`);
      followBtn.textContent = followButtonLabel;

      followBtn.addEventListener('click', () => {
        const updatedFollowState = !following;
        postFollowItem({
          id,
          following: updatedFollowState,
          hidden,
        }).then((response) => {
          if (response.ok) {
            const wasFollowing = following;
            following = updatedFollowState;
            renderButtons('follow');
            if (typeof browserStoreCache === 'function') {
              browserStoreCache('remove');
            }
            showTagSnackbar(
              `You have ${wasFollowing ? 'un' : ''}followed ${name}.`,
            );
            return;
          }
          showTagSnackbar('An error has occurred.');
        });
      });

      group.appendChild(followBtn);
      nextFollowBtn = followBtn;
    }

    const hideButtonLabel = hidden ? 'Unhide' : 'Hide';
    const hideBtn = document.createElement('button');
    hideBtn.type = 'button';
    hideBtn.className = `c-btn ${
      hidden ? 'c-btn--primary c-btn--destructive' : ''
    }`;
    hideBtn.setAttribute('aria-label', `${hideButtonLabel} tag: ${name}`);
    hideBtn.textContent = hideButtonLabel;

    hideBtn.addEventListener('click', () => {
      const updatedHiddenState = !hidden;
      const updatedFollowState = updatedHiddenState;

      postFollowItem({
        id,
        hidden: updatedHiddenState,
        following: updatedFollowState,
      }).then((response) => {
        if (response.ok) {
          const wasHidden = hidden;
          hidden = updatedHiddenState;
          following = updatedFollowState;
          renderButtons('hide');
          if (typeof browserStoreCache === 'function') {
            browserStoreCache('remove');
          }
          showTagSnackbar(`You have ${wasHidden ? 'un' : ''}hidden ${name}.`);
          return;
        }
        showTagSnackbar('An error has occurred.');
      });
    });

    group.appendChild(hideBtn);

    const existingGroup = container.querySelector('.flex.gap-2');
    const shouldRestoreFocus = Boolean(
      activeAction && existingGroup?.contains(document.activeElement),
    );
    if (existingGroup) {
      existingGroup.replaceWith(group);
    } else {
      container.prepend(group);
    }
    if (shouldRestoreFocus) {
      const targetBtn =
        activeAction === 'follow' ? nextFollowBtn || hideBtn : hideBtn;
      targetBtn?.focus();
    }
  };

  renderButtons();
}

/**
 * Hydrates all `.js-tag-card` elements on the page with the signed-in user's followed/hidden state.
 * @param {Object} currentUser The signed-in user object.
 */
function renderPage(currentUser) {
  try {
    const tagCards = document.getElementsByClassName('js-tag-card');
    const followedTags = JSON.parse(currentUser.followed_tags || '[]');

    Array.from(tagCards).forEach((element) => {
      const followedTag = followedTags.find(
        (tag) => tag.id == element.dataset.tagId,
      );
      const following = followedTag?.points >= 0;
      const hidden = followedTag?.points < 0;

      mountTagButtons(
        document.getElementById(`tag-buttons-${element.dataset.tagId}`),
        {
          id: element.dataset.tagId,
          name: element.dataset.tagName,
          isFollowing: following || hidden,
          isHidden: hidden,
        },
      );
    });
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Unable to load tags', error);
  }
}

/**
 * Adds an event listener to the inner page content, to handle any and all follow button clicks with a single handler
 */
function listenForButtonClicks() {
  document
    .getElementById('page-content-inner')
    ?.addEventListener('click', handleButtonClick);
}

/**
 * Opens the login modal when a signed-out visitor clicks a follow or hide tag button.
 * @param {Event} event The delegated click event.
 */
function handleButtonClick({ target }) {
  let trigger;

  if (target.classList.contains('js-follow-tag-button')) {
    trigger = 'follow_button';
  }

  if (target.classList.contains('js-hide-tag-button')) {
    trigger = 'hide_button';
  }

  if (trigger) {
    const trackingData = {
      referring_source: 'tag',
      trigger,
    };
    showLoginModal(trackingData);
  }
}

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

document.ready.then(() => {
  const userStatus = document.body.getAttribute('data-user-status');

  if (userStatus === 'logged-out') {
    listenForButtonClicks();
    return;
  }

  getUserDataAndCsrfTokenSafely()
    .then(({ currentUser, csrfToken }) => {
      if (!currentUser) return;
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;
      renderPage(currentUser);
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    });
});
