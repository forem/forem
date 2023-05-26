import { openDropdown, closeDropdown } from '@utilities/dropdownUtils';

// We present up to 50 users in the UI at once, and for performance reasons we don't want to add individual click listeners to each dropdown menu or inner menu item
// Instead we listen for click events anywhere in the table, and identify required actions based on data attributes of the target
document
  .getElementById('reaction-content')
  ?.addEventListener('click', ({ target }) => {
    const {
      dataset: { markValid, markInvalid, toggleDropdown },
    } = target;

    if (markValid) {
      closeCurrentlyOpenDropdown();
      return;
    }

    if (markInvalid) {
      closeCurrentlyOpenDropdown();
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
