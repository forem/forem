import { initializeDropdown } from '@utilities/dropdownUtils';
import { showModalAfterError } from '@utilities/showUserAlertModal';

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
 * Checks a click event's target to see which button was clicked and calls the relevant handlers
 *
 * @param {HTMLElement} target The target of the click event
 */
function handleClick({ target }) {
  const tagContainer = target.closest('.dashboard__tag__container');

  if (target.classList.contains('follow-button')) {
    handleFollowingButtonClick(tagContainer);
  }

  if (target.classList.contains('hide-button')) {
    handleHideButtonClick(tagContainer);
  }

  if (target.classList.contains('unhide-button')) {
    handleUnhideButtonClick(tagContainer);
  }
}

function fetchFollows(body) {
  const tokenMeta = document.querySelector("meta[name='csrf-token']");
  const csrfToken = tokenMeta && tokenMeta.getAttribute('content');

  return window.fetch('/follows', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
    credentials: 'same-origin',
  });
}

function handleFollowingButtonClick(tagContainer) {
  const { tagId, followId } = tagContainer.dataset;

  const data = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'unfollow',
  };

  fetchFollows(data)
    .then((response) => {
      if (response.ok) {
        removeElementFromPage(followId);
        updateNavigationItemCount();
      } else {
        showModalAfterError({
          response,
          element: 'follow action',
          action_ing: 'updating',
          action_past: 'updated',
        });
      }
    })
    .catch((error) => console.error(error));
}

function handleHideButtonClick(tagContainer) {
  const { tagId, followId } = tagContainer.dataset;

  const data = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'follow',
    explicit_points: -1,
  };

  fetchFollows(data)
    .then((response) => {
      if (response.ok) {
        removeElementFromPage(followId);

        // update the current navigation item count
        updateNavigationItemCount();

        // update the hidden tags navigation item
        const hiddenTagsNavigationItem = document.querySelector(
          '.js-hidden-tags-link .c-indicator',
        );
        updateNavigationItemCount(hiddenTagsNavigationItem, 1);
      } else {
        showModalAfterError({
          response,
          element: 'hide action',
          action_ing: 'updating',
          action_past: 'updated',
        });
      }
    })
    .catch((error) => {
      console.error('Unable to hide tag', error);
    });
}

function handleUnhideButtonClick(tagContainer) {
  const { tagId, followId } = tagContainer.dataset;

  const data = {
    followable_type: 'Tag',
    followable_id: tagId,
    verb: 'unfollow',
  };

  fetchFollows(data)
    .then((response) => {
      if (response.ok) {
        removeElementFromPage(followId);
        // update the current navigation item count
        updateNavigationItemCount();
      } else {
        showModalAfterError({
          response,
          element: 'unhide action',
          action_ing: 'updating',
          action_past: 'updated',
        });
      }
    })
    .catch((error) => console.error(error));
}

function removeElementFromPage(followId) {
  document.getElementById(`follows-${followId}`).remove();
}

function updateNavigationItemCount(
  navItem = document.querySelector('.crayons-link--current .c-indicator'),
  adjustment = -1,
) {
  const currentFollowingTagsCount = parseInt(navItem.innerHTML, 10);
  navItem.textContent = currentFollowingTagsCount + adjustment;
}

/**
 * Initializes the dropdown within each card
 */
const allButtons = document.querySelectorAll('.follow-button');
allButtons.forEach((button) => {
  const { tagId } = button.closest('.dashboard__tag__container').dataset;
  initializeDropdown({
    triggerElementId: `options-dropdown-trigger-${tagId}`,
    dropdownContentId: `options-dropdown-${tagId}`,
  });
});

/**
 * When there is a change to the DOMTree, we find the added node and initializes the dropdown
 */
const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      mutation.addedNodes.forEach((node) => {
        // to remove options like #text '\n  '
        if (node.hasChildNodes()) {
          const { tagId } = node.closest('.dashboard__tag__container').dataset;
          initializeDropdown({
            triggerElementId: `options-dropdown-trigger-${tagId}`,
            dropdownContentId: `options-dropdown-${tagId}`,
          });
        }
      });
    }
  });
});

/**
 * Observes when there additions to the DOM(like when we paginate) within the wrapper
 */
document.querySelectorAll('#following-wrapper').forEach((tagContainer) => {
  observer.observe(tagContainer, {
    childList: true,
    subtree: true,
  });
});

InstantClick.on('change', () => {
  observer.disconnect();
});

window.addEventListener('beforeunload', () => {
  observer.disconnect();
});
