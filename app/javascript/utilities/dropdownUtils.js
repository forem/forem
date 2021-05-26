/**
 * Helper query string to identify interactive/focusable HTML elements
 */
const INTERACTIVE_ELEMENTS_QUERY =
  'button, [href], input, select, textarea, [tabindex="0"]';

/**
 * Used to close the given dropdown if:
 * - Escape is pressed
 * - Tab is pressed and the newly focused element doesn't exist inside the dropdown
 *
 * @param {string} triggerElementId The id of the button which activates the dropdown
 * @param {string} dropdownContentId The id of the dropdown content element
 */
const keyUpListener = (triggerElementId, dropdownContentId) => {
  return ({ key }) => {
    if (key === 'Escape') {
      // Close the dropdown and return focus to the trigger button to prevent focus being lost
      const triggerElement = document.getElementById(triggerElementId);
      const isCurrentlyOpen =
        triggerElement.getAttribute('aria-expanded') === 'true';
      if (isCurrentlyOpen) {
        closeDropdown(triggerElementId, dropdownContentId);
        triggerElement.focus();
      }
    } else if (key === 'Tab') {
      // Close the dropdown if the user has tabbed away from it
      const isInsideDropdown = document
        .getElementById(dropdownContentId)
        ?.contains(document.activeElement);
      if (!isInsideDropdown) {
        closeDropdown(triggerElementId, dropdownContentId);
      }
    }
  };
};

/**
 * Used to listen for a click outside of a dropdown while it's open.
 * Closes the dropdown and refocuses the trigger button, if another interactive item has not been clicked.
 *
 * @param {string} triggerElementId The id of the button which activates the dropdown
 * @param {string} dropdownContent The id of the dropdown content element
 */
const clickOutsideListener = (triggerElementId, dropdownContentId) => {
  return ({ target }) => {
    const triggerElement = document.getElementById(triggerElementId);
    const dropdownContent = document.getElementById(dropdownContentId);
    if (
      target !== triggerElement &&
      !dropdownContent.contains(target) &&
      !triggerElement.contains(target)
    ) {
      closeDropdown(triggerElementId, dropdownContentId);

      //   If the user did not click on another interactive item, return focus to the trigger
      if (!target.matches(INTERACTIVE_ELEMENTS_QUERY)) {
        triggerElement.focus();
      }
    }
  };
};

const openDropdown = (triggerElementId, dropdownContentId) => {
  const dropdownContent = document.getElementById(dropdownContentId);
  const triggerElement = document.getElementById(triggerElementId);

  triggerElement.setAttribute('aria-expanded', 'true');

  // Style set inline to prevent specificity issues
  dropdownContent.style.display = 'block';

  // Send focus to the first suitable element
  dropdownContent.querySelector(INTERACTIVE_ELEMENTS_QUERY)?.focus();

  document.addEventListener(
    'keyup',
    keyUpListener(triggerElementId, dropdownContentId),
  );

  document.addEventListener(
    'click',
    clickOutsideListener(triggerElementId, dropdownContentId),
  );
};

const closeDropdown = (triggerElementId, dropdownContentId) => {
  const dropdownContent = document.getElementById(dropdownContentId);

  document
    .getElementById(triggerElementId)
    ?.setAttribute('aria-expanded', 'false');

  dropdownContent.style.display = 'none';

  document.removeEventListener(
    'keyup',
    keyUpListener(triggerElementId, dropdownContentId),
  );

  document.removeEventListener(
    'click',
    clickOutsideListener(triggerElementId, dropdownContentId),
  );
};

const toggleDropdown = (triggerElementId, dropdownContentId) => {
  const isAlreadyOpen =
    document.getElementById(triggerElementId)?.getAttribute('aria-expanded') ===
    'true';

  if (isAlreadyOpen) {
    closeDropdown(triggerElementId, dropdownContentId);
  } else {
    openDropdown(triggerElementId, dropdownContentId);
  }
};

export const initializeDropdown = ({
  triggerButtonElementId,
  dropdownContentElementId,
}) => {
  const triggerButton = document.getElementById(triggerButtonElementId);
  const dropdownContent = document.getElementById(dropdownContentElementId);

  if (!triggerButton || !dropdownContent) {
    // The required props haven't been provided, do nothing
    return;
  }

  //   Ensure default values have been applied
  triggerButton.setAttribute('aria-expanded', 'false');
  triggerButton.setAttribute('aria-controls', dropdownContentElementId);
  triggerButton.setAttribute('aria-haspopup', 'true');

  triggerButton.addEventListener('click', () =>
    toggleDropdown(triggerButtonElementId, dropdownContentElementId),
  );

  return {
    closeDropdown: () =>
      closeDropdown(triggerButtonElementId, dropdownContentElementId),
  };
};
