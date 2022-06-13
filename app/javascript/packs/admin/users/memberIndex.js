import { showUserModal } from './editUserModals';
import { openDropdown, closeDropdown } from '@utilities/dropdownUtils';
import { copyToClipboard } from '@utilities/runtime';
import { showWindowModal, closeWindowModal } from '@utilities/showModal';

// We present up to 50 users in the UI at once, and for performance reasons we don't want to add individual click listeners to each dropdown menu or inner menu item
// Instead we listen for click events anywhere in the table, and identify required actions based on data attributes of the target
document
  .getElementById('member-index-content')
  ?.addEventListener('click', ({ target }) => {
    const {
      dataset: { copyEmail, toggleDropdown },
    } = target;

    if (copyEmail) {
      handleEmailCopy(copyEmail);
      return;
    }

    if (toggleDropdown) {
      handleDropdownToggle({
        triggerElementId: target.getAttribute('id'),
        dropdownContentId: toggleDropdown,
      });
      return;
    }
  });

// We keep track of the currently opened dropdown to make sure we only ever have one open at a time
let currentlyOpenDropdownId;

const handleDropdownToggle = ({ triggerElementId, dropdownContentId }) => {
  const triggerButton = document.getElementById(triggerElementId);

  const isCurrentlyOpen =
    triggerButton.getAttribute('aria-expanded') === 'true';

  if (isCurrentlyOpen) {
    closeDropdown({ triggerElementId, dropdownContentId });
    triggerButton.focus();
    currentlyOpenDropdownId = null;
  } else {
    closeCurrentlyOpenDropdown();
    openDropdown({ triggerElementId, dropdownContentId });
    currentlyOpenDropdownId = dropdownContentId;
  }
};

/**
 * Make sure any currently opened dropdown is closed
 */
const closeCurrentlyOpenDropdown = (focusTrigger = false) => {
  if (!currentlyOpenDropdownId) {
    return;
  }
  const triggerButton = document.querySelector(
    `[aria-controls='${currentlyOpenDropdownId}']`,
  );

  closeDropdown({
    dropdownContentId: currentlyOpenDropdownId,
    triggerElementId: triggerButton?.getAttribute('id'),
  });

  if (focusTrigger) {
    triggerButton.focus();
  }
};

// We listen for key up events on this page to make sure users can close the dropdowns via keyboard
document.addEventListener('keyup', ({ key }) => {
  if (key === 'Escape') {
    closeCurrentlyOpenDropdown(true);
    return;
  }
  if (key === 'Tab') {
    // If we're not inside a dropdown any more, let's close it
    const closestDropdown = document.activeElement.closest('.crayons-dropdown');
    if (!closestDropdown) {
      closeCurrentlyOpenDropdown();
    }
  }
});

/**
 * Helper function to copy the given text to the clipboard and display a snackbar confirmation.
 *
 * @param {string} copyEmail The email to copy
 */
const handleEmailCopy = (copyEmail) => {
  copyToClipboard(copyEmail)
    .then(() => {
      document.dispatchEvent(
        new CustomEvent('snackbar:add', {
          detail: { message: 'Copied to clipboard' },
        }),
      );
      closeCurrentlyOpenDropdown(true);
    })
    .catch(() => {
      document.dispatchEvent(
        new CustomEvent('snackbar:add', {
          detail: {
            message: 'Unable to copy the text. Try reloading the page',
          },
        }),
      );
    });
};

// The reason that we loop through the elements is because we have alternate layouts
// for different screen sizes
document.querySelectorAll('.js-export-csv-modal-trigger').forEach((item) => {
  item.addEventListener('click', () => {
    showWindowModal({
      title: 'Download Member Data',
      contentSelector: item.dataset.modalContentSelector,
      overlay: true,
      onOpen: () => {
        document
          .querySelector('#window-modal .js-export-csv-modal-cancel')
          ?.addEventListener('click', closeWindowModal);
      },
    });
  });
});

document.body.addEventListener('click', showUserModal);
