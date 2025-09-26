import { getInstantClick } from '../topNavigation/utilities';
import { waitOnBaseData } from '../utilities/waitOnBaseData';
import { locale } from '@utilities/locale';

/* global showLoginModal  userData  showModalAfterError browserStoreCache */

let observer;

/**
 * Sets the text content of the button to the correct 'Follow' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */

function addButtonFollowText(button, style) {
  const { name, className } = JSON.parse(button.dataset.info);

  switch (style) {
    case 'small':
      addAriaLabelToButton({
        button,
        followName: name,
        followType: className,
        style: 'follow',
      });
      button.textContent = '+';
      break;
    case 'follow-back':
      addAriaLabelToButton({
        button,
        followName: name,
        followType: className,
        style: 'follow-back',
      });
      button.textContent = locale('core.follow_back');
      break;
    default:
      addAriaLabelToButton({
        button,
        followName: name,
        followType: className,
        style: 'follow',
      });
      button.textContent = locale('core.follow');
  }
}

/**
 * Sets the aria-label and aria-pressed value of the button
 *
 * @param {HTMLElement} button The Follow button to update.
 * @param {string} followType The followableType of the button.
 * @param {string} followName The name of the followable to be followed.
 * @param {string} style The style of the button from its "info" data attribute
 */
function addAriaLabelToButton({ button, followType, followName, style = '' }) {
  let label = '';
  let pressed = '';
  switch (style) {
    case 'follow':
      label = `Follow ${followType.toLowerCase()}: ${followName}`;
      pressed = 'false';
      break;
    case 'follow-back':
      label = `Follow ${followType.toLowerCase()} back: ${followName}`;
      pressed = 'false';
      break;
    case 'following':
      label = `Follow ${followType.toLowerCase()}: ${followName}`;
      pressed = 'true';
      break;
    case 'self':
      label = `Edit profile`;
      break;
    default:
      label = `Follow ${followType.toLowerCase()}: ${followName}`;
      pressed = 'false';
  }
  button.setAttribute('aria-label', label);
  pressed.length === 0
    ? button.removeAttribute('aria-pressed')
    : button.setAttribute('aria-pressed', pressed);
}

/**
 * Sets the text content of the button to the correct 'Following' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */
function addButtonFollowingText(button, style) {
  button.textContent = style === 'small' ? '✓' : locale('core.following');
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

  // Often there are multiple follow buttons for the same followable item on the page
  // We collect all buttons which match the click, and update them all
  const matchingFollowButtons = Array.from(
    document.getElementsByClassName('follow-action-button'),
  ).filter((btn) => {
    const { info } = btn.dataset;
    if (info) {
      const { id, className } = JSON.parse(info);
      return id === buttonInfo.id && className === buttonInfo.className;
    }
    return false;
  });

  matchingFollowButtons.forEach((matchingButton) => {
    matchingButton.classList.add('showing');

    switch (newState) {
      case 'follow':
      case 'follow-back':
        updateFollowButton(matchingButton, newState, buttonInfo);
        break;
      case 'login':
        addButtonFollowText(matchingButton, style);
        break;
      case 'self':
        updateUserOwnFollowButton(matchingButton);
        break;
      default:
        updateFollowingButton(matchingButton, style);
    }
  });
}

/**
 * Set the Follow button's UI to the 'following' state
 *
 * @param {HTMLElement} button The Follow button to be updated
 * @param {string} style Style of the follow button (e.g. 'small')
 */
function updateFollowingButton(button, style) {
  const { name, className } = JSON.parse(button.dataset.info);
  button.dataset.verb = 'follow';
  addButtonFollowingText(button, style);
  button.classList.remove('crayons-btn--primary');
  button.classList.remove('crayons-btn--secondary');
  button.classList.add('crayons-btn--outlined');
  addAriaLabelToButton({
    button,
    followName: name,
    followType: className,
    style: 'following',
  });
}

/**
 * Update the UI of the given button to the user's own button - i.e. 'Edit profile'
 *
 * @param {HTMLElement} button The Follow button to be updated
 */
function updateUserOwnFollowButton(button) {
  button.dataset.verb = 'self';
  button.textContent = locale('core.edit_profile');
  addAriaLabelToButton({
    button,
    followName: '',
    followType: '',
    style: 'self',
  });
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

/**
 * Checks a click event's target, and if it is a follow button, triggers the appropriate follow action
 *
 * @param {HTMLElement} target The target of the click event
 */
function handleFollowButtonClick({ target }) {
  if (
    target.classList.contains('follow-action-button') ||
    target.classList.contains('follow-user') ||
    target.classList.contains('follow-subforem')
  ) {
    const userStatus = document.body.getAttribute('data-user-status');
    if (userStatus === 'logged-out') {
      let trackingData = {};
      if (determineSecondarySource(target)) {
        trackingData = {
          referring_source: determineSecondarySource(target),
          trigger: 'follow_button',
        };
      }
      showLoginModal(trackingData);
      return;
    }

    optimisticallyUpdateButtonUI(target);
    browserStoreCache('remove');

    const { verb } = target.dataset;

    if (verb === 'self') {
      window.location.href = '/settings';
      return;
    }

    const { className, id } = JSON.parse(target.dataset.info);
    const formData = new FormData();
    formData.append('followable_type', className);
    formData.append('followable_id', id);
    formData.append('verb', verb);
    getCsrfToken()
      .then(sendFetch('follow-creation', formData))
      .then((response) => {
        if (response.status !== 200) {
          showModalAfterError({
            response,
            element: 'user',
            action_ing: 'following',
            action_past: 'followed',
            timeframe: 'for a day',
          });
        }
      });
  }
}

/**
 * Determines where the click came from for event tracking
 */
function determineSecondarySource(target) {
  // The follow user buttons have both follow-action-button and follow-user
  // classnames on them. For now we only want to
  // implement tracking for follow-user.
  if (target.classList.contains('follow-user')) {
    return 'user';
  }
}

/**
 * Adds an event listener to the page to handle any and all follow button clicks with a single handler
 */
function listenForFollowButtonClicks() {
  if (document.body.dataset.followHandlerInitialized === 'true') {
    return;
  }
  document.body.addEventListener('click', handleFollowButtonClick);
  document.body.dataset.followHandlerInitialized = 'true';
}

/**
 * Sets the UI of the button based on the current following status
 *
 * @param {string} followStatus The current following status for the button
 * @param {HTMLElement} button The button to update
 */
function updateInitialButtonUI(followStatus, button) {
  const buttonInfo = JSON.parse(button.dataset.info);
  const { style } = buttonInfo;
  button.classList.add('showing');

  switch (followStatus) {
    case 'true':
    case 'mutual':
      updateFollowingButton(button, style);
      break;
    case 'follow-back':
      addButtonFollowText(button, followStatus);
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

/**
 * Fetches all 'follow statuses' for the given IDs and type, and then updates the UI for all related buttons.
 *
 * @param {Object} idButtonHash A hash of IDs and the array of buttons which relate to them
 * @param {string} followableType The type of followable (e.g. 'User', 'Subforem')
 */
function fetchBulkFollowStatuses(idButtonHash, followableType) {
  const url = new URL('/follows/bulk_show', document.location);
  const searchParams = new URLSearchParams();
  Object.keys(idButtonHash).forEach((id) => {
    searchParams.append('ids[]', id);
  });
  searchParams.append('followable_type', followableType);
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
        });
      });
    });
}

/**
 * Sets up the initial state of all bulk-eligible follow buttons on the page (e.g. users, subforems).
 * It obtains the 'follow status' of each item and updates the associated buttons' UI.
 */
function initializeBulkFollowButtons() {
  const buttons = document.querySelectorAll(
    '.follow-action-button.follow-user:not([data-fetched]), .follow-action-button.follow-subforem:not([data-fetched])',
  );

  if (buttons.length === 0) {
    return;
  }

  const followables = {};

  Array.from(buttons, (button) => {
    button.dataset.fetched = 'fetched';
    const { userStatus } = document.body.dataset;
    const buttonInfo = JSON.parse(button.dataset.info);
    const { name, className } = buttonInfo;

    if (userStatus === 'logged-out') {
      const { style } = buttonInfo;
      addButtonFollowText(button, style);
    } else {
      addAriaLabelToButton({ button, followType: className, followName: name });
      const { id } = buttonInfo;
      if (!followables[className]) {
        followables[className] = {};
      }
      const idHash = followables[className];
      if (idHash[id]) {
        idHash[id].push(button);
      } else {
        idHash[id] = [button];
      }
    }
  });

  if (Object.keys(followables).length > 0) {
    Object.keys(followables).forEach((followableType) => {
      fetchBulkFollowStatuses(followables[followableType], followableType);
    });
  }
}

/**
 * Individually fetches the current status of a follow button and updates the UI to match
 *
 * @param {HTMLElement} button
 * @param {Object} buttonInfo The parsed buttonInfo object obtained from the button's data-attribute
 */
function fetchFollowButtonStatus(button, buttonInfo) {
  button.dataset.fetched = 'fetched';

  fetch(`/follows/${buttonInfo.id}?followable_type=${buttonInfo.className}`, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  })
    .then((response) => response.text())
    .then((followStatus) => {
      updateInitialButtonUI(followStatus, button);
    });
}

/**
 * Makes sure the initial state of follow buttons is fetched and presented in the UI.
 * Buttons eligible for bulk fetching are initialized separately.
 */
function initializeNonBulkFollowButtons() {
  const nonBulkFollowButtons = document.querySelectorAll(
    '.follow-action-button:not(.follow-user):not(.follow-subforem):not([data-fetched])',
  );

  waitOnBaseData().then(() => {
    const userLoggedIn =
      document.body.getAttribute('data-user-status') === 'logged-in';

    const user = userLoggedIn ? userData() : null;
    const followedTags = user
      ? JSON.parse(user.followed_tags).map((tag) => tag.id)
      : [];

    const followedTagIds = new Set(followedTags);

    nonBulkFollowButtons.forEach((button) => {
      const { info } = button.dataset;
      const buttonInfo = JSON.parse(info);
      const { className, name } = buttonInfo;
      addAriaLabelToButton({ button, followType: className, followName: name });
      if (user === null) {
        return; // No need to fetch the status if the user is logged out
      }
      if (className === 'Tag' && user) {
        // We don't need a network request to 'fetch' the status of tag buttons
        button.dataset.fetched = true;
        const initialButtonFollowState = followedTagIds.has(buttonInfo.id)
          ? 'true'
          : 'false';
        updateInitialButtonUI(initialButtonFollowState, button);
      } else {
        fetchFollowButtonStatus(button, buttonInfo);
      }
    });
  });
}

const setupFollowFunctionality = () => {
  initializeBulkFollowButtons();
  initializeNonBulkFollowButtons();

  if (observer) {
    observer.disconnect();
  }

  observer = new MutationObserver((mutationsList) => {
    mutationsList.forEach((mutation) => {
      if (mutation.type === 'childList') {
        initializeBulkFollowButtons();
        initializeNonBulkFollowButtons();
      }
    });
  });

  document
    .querySelectorAll('[data-follow-button-container]')
    .forEach((followButtonContainer) => {
      observer.observe(followButtonContainer, {
        childList: true,
        subtree: true,
      });
    });
};

listenForFollowButtonClicks();

setupFollowFunctionality();

getInstantClick().then((ic) => {
  ic.on('change', setupFollowFunctionality);
});

window.addEventListener('beforeunload', () => {
  if (observer) {
    observer.disconnect();
  }
});