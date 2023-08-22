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

// TODO: need to discinnect the observer
const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      mutation.addedNodes.forEach((node) => {
        // to remove options like #text '\n  '
        if (node.hasChildNodes()) {
          const { tagId } = node.dataset;
          initializeDropdown({
            triggerElementId: `options-dropdown-trigger-${tagId}`,
            dropdownContentId: `options-dropdown-${tagId}`,
          });
        }
      });
    }
  });
});

document.querySelectorAll('#following-wrapper').forEach((tagContainer) => {
  observer.observe(tagContainer, {
    childList: true,
    subtree: true,
  });
});

/**
 * Adds an event listener to the inner page content, to handle any and all follow button clicks with a single handler
 */
function listenForButtonClicks() {
  document
    .getElementById('following-wrapper')
    .addEventListener('click', handleClick);
}

/**
 * Checks a click event's target to see which button was clicked and calls the relevant handlers
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

  if (target.classList.contains('unhide-button')) {
    handleUnhideButtonClick(target);
  }
}

function fetchFollows(body) {
  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  window
    .fetch('/follows', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
      credentials: 'same-origin',
    })
    .catch((error) => console.error(error)); //maybe show a modal here instead.
}

function handleFollowingButtonClick(target) {
  const { tagId, followId } = target.dataset;

  const data = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'unfollow',
  };
  fetchFollows(data);

  document.getElementById(`follows-${followId}`).remove();

  const currentNavigationItem = document.querySelector(
    '.crayons-link--current .c-indicator',
  );
  const currentFollowingTagsCount = parseInt(currentNavigationItem.innerHTML);
  currentNavigationItem.textContent = currentFollowingTagsCount - 1;
}

function handleHideButtonClick(target) {
  const { tagId, followId } = target.dataset;

  const data = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'follow',
    explicit_points: -1,
  };

  fetchFollows(data);

  // TODO: this should be done on success
  // TODO: the follow and tag id needs to move to the parent container and used from there.
  document.getElementById(`follows-${followId}`).remove();
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

function handleUnhideButtonClick(target) {
  const { tagId, followId } = target.dataset;

  const data = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'follow',
    explicit_points: 1,
  };
  fetchFollows(data);

  // TODO: this should be done on success
  document.getElementById(`follows-${followId}`).remove();
  const currentNavigationItem = document.querySelector(
    '.crayons-link--current .c-indicator',
  );
  const currentFollowingTagsCount = parseInt(currentNavigationItem.innerHTML);
  currentNavigationItem.textContent = currentFollowingTagsCount - 1;
  const followingTagsNavigationItem = document.querySelector(
    '.js-following-tags-link .c-indicator',
  );
  const currentHiddenTagsCount = parseInt(
    followingTagsNavigationItem.innerHTML,
  );
  followingTagsNavigationItem.textContent = currentHiddenTagsCount + 1;
}
