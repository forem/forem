import { h, render } from 'preact';
import { Snackbar } from '../Snackbar/Snackbar';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

/* global showLoginModal  */

// This Pack file has some dependencies for it to function accurately:
// Copy and paste the FOllow and Hide button snippets from a tag card.
// An example can be found in app/views/tags/index.html.erb
// The tag card needs to contain a class .js-tag-card elements,
// with data attributes for the tag-id and name.
// The follow button and the hide button need to contain classes
// js-follow-tag-button and/or js-hide-tag-button respectively.

function renderPage(currentUser) {
  import('../tags/TagButtonContainer')
    .then(({ Tag }) => {
      const tagCards = document.getElementsByClassName('js-tag-card');

      const followedTags = JSON.parse(currentUser.followed_tags);
      Array.from(tagCards).forEach((element) => {
        const followedTag = followedTags.find(
          (tag) => tag.id == element.dataset.tagId,
        );
        const following = followedTag?.points >= 0;
        const hidden = followedTag?.points < 0;

        render(
          <Tag
            id={element.dataset.tagId}
            name={element.dataset.tagName}
            isFollowing={following || hidden}
            isHidden={hidden}
          />,
          document.getElementById(`tag-buttons-${element.dataset.tagId}`),
        );
      });
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Unable to load tags', error);
    });
}

/**
 * Adds an event listener to the inner page content, to handle any and all follow button clicks with a single handler
 */
function listenForButtonClicks() {
  document
    .getElementById('page-content-inner')
    .addEventListener('click', handleButtonClick);
}

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

function loadSnackbar() {
  const snackZone = document.getElementById('snack-zone');

  if (snackZone) {
    render(<Snackbar lifespan="1" />, document.getElementById('snack-zone'));
  }
}

document.ready.then(() => {
  const userStatus = document.body.getAttribute('data-user-status');
  loadSnackbar();

  if (userStatus === 'logged-out') {
    listenForButtonClicks();
    return;
  }

  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;
      renderPage(currentUser);
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    });
});

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});
