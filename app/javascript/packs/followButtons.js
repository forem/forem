/* global showLoginModal */

/**
 * Sets the text content of the button to the correct 'Follow' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */
function addButtonFollowText(button, style) {
  switch (style) {
    case 'small':
      button.textContent = '+';
      break;
    case 'follow-back':
      button.textContent = 'Follow back';
      break;
    default:
      button.textContent = 'Follow';
  }
}

/**
 * Sets the text content of the button to the correct 'Following' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */
function addButtonFollowingText(button, style) {
  button.textContent = style === 'small' ? '✓' : 'Following';
}

/**
 * Changes the visual appearance and 'verb' of the button to match the new state
 *
 * @param {HTMLElement} button The Follow button to be updated
 */
function optimisticallyUpdateButtonUI(button) {
  const { verb: newState } = button.dataset;
  const buttonInfo = JSON.parse(button.dataset.info);
  const { style } = buttonInfo;

  button.classList.add('showing');

  switch (newState) {
    case 'follow':
    case 'follow-back':
      updateFollowButton(button, newState, buttonInfo);
      break;
    case 'login':
      addButtonFollowText(button, style);
      break;
    case 'self':
      updateUserOwnFollowButton(button);
      break;
    default:
      updateFollowingButton(button, style);
  }
}

/**
 * Set the Follow button's UI to the 'following' state
 *
 * @param {HTMLElement} button The Follow button to be updated
 * @param {string} style Style of the follow button (e.g. 'small')
 */
function updateFollowingButton(button, style) {
  button.dataset.verb = 'follow';
  addButtonFollowingText(button, style);
  button.classList.remove('crayons-btn--primary');
  button.classList.remove('crayons-btn--secondary');
  button.classList.add('crayons-btn--outlined');
}

/**
 * Update the UI of the given button to the user's own button - i.e. 'Edit profile'
 *
 * @param {HTMLElement} button The Follow button to be updated
 */
function updateUserOwnFollowButton(button) {
  button.dataset.verb = 'self';
  button.textContent = 'Edit profile';
}

/**
 * Update the UI of the given button to the 'follow' or 'follow-back' state
 *
 * @param {HTMLElement} button The Follow button to be updated
 * @param {string} newState The new follow state of the button
 * @param {Object} buttonInfo The parsed info object obtained from the button's dataset
 * @param {string} buttonInfo.style The style of the follow button (e.g 'small')
 * @param {string} buttonInfo.followStyle The crayons button variant (e.g 'primary')
 */
function updateFollowButton(button, newState, buttonInfo) {
  const { style, followStyle } = buttonInfo;

  button.dataset.verb = 'unfollow';
  button.classList.remove('crayons-btn--outlined');

  if (followStyle === 'primary') {
    button.classList.add('crayons-btn--primary');
  } else if (followStyle === 'secondary') {
    button.classList.add('crayons-btn--secondary');
  }

  const nextButtonStyle = newState === 'follow-back' ? newState : style;
  addButtonFollowText(button, nextButtonStyle);
}

function handleFollowButtonClick(event) {
  const { target } = event;
  if (
    target.classList.contains('follow-action-button') ||
    target.classList.contains('follow-user')
  ) {
    optimisticallyUpdateButtonUI(target);

    const { verb } = target.dataset;

    if (verb === 'self') {
      window.location.href = '/settings';
      return;
    }

    if (verb === 'login') {
      showLoginModal();
    }

    const buttonDataInfo = JSON.parse(target.dataset.info);
    const formData = new FormData();
    formData.append('followable_type', buttonDataInfo.className);
    formData.append('followable_id', buttonDataInfo.id);
    formData.append('verb', verb);
    getCsrfToken().then(sendFetch('follow-creation', formData));
  }
}

function listenForFollowButtonClicks() {
  document
    .getElementById('page-content-inner')
    .addEventListener('click', handleFollowButtonClick);
}

function updateInitialButtonUI(response, button) {
  const buttonInfo = JSON.parse(button.dataset.info);
  const { style } = buttonInfo;
  button.classList.add('showing');

  switch (response) {
    case 'true':
    case 'mutual':
      updateFollowingButton(button, style);
      break;
    case 'follow-back':
      addButtonFollowText(button, style);
      break;
    case 'false':
      updateFollowButton(button, 'follow', buttonInfo);
      break;
    case 'self':
      updateUserOwnFollowButton(button);
      break;
    default:
      addButtonFollowText(button, style);
  }
}

function fetchUserFollowStatuses(idButtonHash) {
  const url = new URL('/follows/bulk_show', document.location);
  const searchParams = new URLSearchParams();
  Object.keys(idButtonHash).forEach((id) => {
    searchParams.append('ids[]', id);
  });
  searchParams.append('followable_type', 'User');
  url.search = searchParams;

  fetch(url, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((idStatuses) => {
      Object.keys(idStatuses).forEach((id) => {
        idButtonHash[id].forEach((button) => {
          updateInitialButtonUI(idStatuses[id], button);
          button.dataset.buttonInitialized = true;
        });
      });
    });
}

function initializeAllUserFollowButtons() {
  const buttons = document.querySelectorAll(
    '.follow-action-button.follow-user:not([data-button-initialized])',
  );

  if (buttons.length === 0) {
    return;
  }

  const userIds = {};

  Array.from(buttons).forEach((button) => {
    const userStatus = document.body.getAttribute('data-user-status');

    if (userStatus === 'logged-out') {
      const { style } = JSON.parse(button.dataset.info);
      addButtonFollowText(button, style);
    } else {
      const { id: userId } = JSON.parse(button.dataset.info);
      if (userIds[userId]) {
        userIds[userId].push(button);
      } else {
        userIds[userId] = [button];
      }
    }
  });

  if (Object.keys(userIds).length > 0) {
    fetchUserFollowStatuses(userIds);
  }
}

initializeAllUserFollowButtons();
listenForFollowButtonClicks();

// TODO: initialize the non-user follow buttons

// TODO: verify lots of combos in the UI

// TODO: catalog all pages with follow buttons, and make sure pack is added
