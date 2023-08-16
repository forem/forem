import { initializeDropdown } from '@utilities/dropdownUtils';

/**
 * Initializes each dropdown within each card
 */
const allButtons = document.querySelectorAll('.follow-button');
allButtons.forEach((button) => {
  const { tagId } = button.dataset;
  initializeDropdown({
    triggerElementId: `options-dropdown-trigger-${tagId}`,
    dropdownContentId: `options-dropdown-${tagId}`,
  });
});

listenForButtonClicks();

/**
 * Adds an event listener to the inner page content, to handle any and all follow button clicks with a single handler
 */
function listenForButtonClicks() {
  document
    .getElementById('following-wrapper')
    .addEventListener('click', handleClick);
}

/**
 * Checks a click event's target to see if it is a follow button, and if so, calls the follow button handler
 *
 * @param {HTMLElement} target The target of the click event
 */
function handleClick({ target }) {
  if (target.classList.contains('follow-button')) {
    handleFollowingButtonClick(target);
  }

  if (target.classList.contains('hide-button')) {
    handleHideButtonClick(target);
  }
}

function handleFollowingButtonClick(target) {
  const { tagId } = target.dataset;
  const { followId } = target.dataset;

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  const dataBody = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'unfollow',
  };

  window
    .fetch('/follows', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(dataBody),
      credentials: 'same-origin',
    })
    .catch((error) => console.error(error)); //maybe show a modal here instead.

  document.getElementById(`follows-${followId}`).style = 'display:none';

  const currentNavigationItem = document.querySelector(
    '.crayons-link--current .c-indicator',
  );
  const currentFollowingTagsCount = parseInt(currentNavigationItem.innerHTML);
  currentNavigationItem.textContent = currentFollowingTagsCount - 1;
}

function handleHideButtonClick(target) {
  const { tagId } = target.dataset;
  const { followId } = target.dataset;

  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  const dataBody = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'follow',
    explicit_points: -1,
  };

  window
    .fetch('/follows', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(dataBody),
      credentials: 'same-origin',
    })
    .catch((error) => console.error(error)); // TODO: maybe show a modal here instead.

  // TODO: this should be done on success
  document.getElementById(`follows-${followId}`).style = 'display:none';
  const currentNavigationItem = document.querySelector(
    '.crayons-link--current .c-indicator',
  );
  const currentFollowingTagsCount = parseInt(currentNavigationItem.innerHTML);
  currentNavigationItem.textContent = currentFollowingTagsCount - 1;
  const hiddenTagsNavigationItem = document.querySelector(
    '.js-hidden-tags-link .c-indicator',
  );
  const currentHiddenTagsCount = parseInt(hiddenTagsNavigationItem.innerHTML);
  hiddenTagsNavigationItem.textContent = currentHiddenTagsCount + 1;
}
