/**
 * Helper query string to identify interactive/focusable HTML elements
 */
const INTERACTIVE_ELEMENTS_QUERY =
  'button, [href], input:not([type="hidden"]), select, textarea, [tabindex="0"]';

/**
 * Used to close the given dropdown if:
 * - Escape is pressed
 * - Tab is pressed and the newly focused element doesn't exist inside the dropdown
 *
 * @param {Object} args
 * @param {string} args.triggerElementId The id of the button which activates the dropdown
 * @param {string} args.dropdownContentId The id of the dropdown content element
 * @param {Function} args.onClose Optional function for any side-effects which should occur on dropdown close
 */
const keyUpListener = ({
  triggerElementId,
  dropdownContentId,
  onClose = () => {},
}) => {
  return ({ key }) => {
    if (key === 'Escape') {
      // Close the dropdown and return focus to the trigger button to prevent focus being lost
      const triggerElement = document.getElementById(triggerElementId);
      const isCurrentlyOpen =
        triggerElement.getAttribute('aria-expanded') === 'true';
      if (isCurrentlyOpen) {
        closeDropdown({ triggerElementId, dropdownContentId, onClose });
        triggerElement.focus();
      }
    } else if (key === 'Tab') {
      // Close the dropdown if the user has tabbed away from it
      const isInsideDropdown = document
        .getElementById(dropdownContentId)
        ?.contains(document.activeElement);
      if (!isInsideDropdown) {
        closeDropdown({ triggerElementId, dropdownContentId, onClose });
      }
    }
  };
};

/**
 * Used to listen for a click outside of a dropdown while it's open.
 * Closes the dropdown and refocuses the trigger button, if another interactive item has not been clicked.
 *
 * @param {Object} args
 * @param {string} args.triggerElementId The id of the button which activates the dropdown
 * @param {string} args.dropdownContentId The id of the dropdown content element
 * @param {Function} args.onClose Optional function for any side-effects which should occur on dropdown close
 */
const clickOutsideListener = ({
  triggerElementId,
  dropdownContentId,
  onClose = () => {},
}) => {
  return ({ target }) => {
    const triggerElement = document.getElementById(triggerElementId);
    const dropdownContent = document.getElementById(dropdownContentId);
    if (!dropdownContent) {
      // User may have navigated away from the page
      return;
    }

    if (
      target !== triggerElement &&
      !dropdownContent.contains(target) &&
      !triggerElement.contains(target)
    ) {
      closeDropdown({ triggerElementId, dropdownContentId, onClose });

      //   If the user did not click on another interactive item, return focus to the trigger
      if (!target.matches(INTERACTIVE_ELEMENTS_QUERY)) {
        triggerElement.focus();
      }
    }
  };
};

/**
 * Open the given dropdown, updating aria attributes, attaching listeners and focus the first interactive element
 *
 * @param {Object} args
 * @param {string} args.triggerElementId The id of the button which activates the dropdown
 * @param {string} args.dropdownContent The id of the dropdown content element
 * @param {Function} args.onClose Optional function for any side-effects which should occur on dropdown close
 */
const openDropdown = ({
  triggerElementId,
  dropdownContentId,
  onClose = () => {},
}) => {
  const dropdownContent = document.getElementById(dropdownContentId);
  const triggerElement = document.getElementById(triggerElementId);

  triggerElement.setAttribute('aria-expanded', 'true');

  // Style set inline to prevent specificity issues
  dropdownContent.style.display = 'block';

  // Send focus to the first suitable element
  dropdownContent.querySelector(INTERACTIVE_ELEMENTS_QUERY)?.focus();

  document.addEventListener(
    'keyup',
    keyUpListener({ triggerElementId, dropdownContentId, onClose }),
  );

  document.addEventListener(
    'click',
    clickOutsideListener({ triggerElementId, dropdownContentId, onClose }),
  );
};

/**
 * Close the given dropdown, updating aria attributes and removing event listeners
 *
 * @param {Object} args
 * @param {string} args.triggerElementId The id of the button which activates the dropdown
 * @param {string} args.dropdownContent The id of the dropdown content element
 * @param {Function} args.onClose Optional function for any side-effects which should occur on dropdown close
 */
const closeDropdown = ({
  triggerElementId,
  dropdownContentId,
  onClose = () => {},
}) => {
  const dropdownContent = document.getElementById(dropdownContentId);

  document
    .getElementById(triggerElementId)
    ?.setAttribute('aria-expanded', 'false');

  dropdownContent.style.display = 'none';

  document.removeEventListener(
    'keyup',
    keyUpListener({ triggerElementId, dropdownContentId, onClose }),
  );

  document.removeEventListener(
    'click',
    clickOutsideListener({ triggerElementId, dropdownContentId, onClose }),
  );
  onClose();
};

/**
 * A helper function to initialize dropdown behaviors. This function attaches open/close click and keyup listeners,
 * and makes sure relevant aria properties and keyboard focus are updated.
 *
 * @param {Object} args
 * @param {string} args.triggerButtonElementId The ID of the button which triggers the dropdown open/close behavior
 * @param {string} args.dropdownContentId The ID of the dropdown content which should open/close on trigger button press
 * @param {Function} args.onClose An optional callback for when the dropdown is closed. This can be passed to execute any side-effects required when the dropdown closes.
 *
 * @returns {{closeDropdown: Function}} Object with callback to close the initialized dropdown
 */
export const initializeDropdown = ({
  triggerElementId,
  dropdownContentId,
  onClose = () => {},
}) => {
  const triggerButton = document.getElementById(triggerElementId);
  const dropdownContent = document.getElementById(dropdownContentId);

  if (!triggerButton || !dropdownContent) {
    // The required props haven't been provided, do nothing
    return;
  }

  // Ensure default values have been applied
  triggerButton.setAttribute('aria-expanded', 'false');
  triggerButton.setAttribute('aria-controls', dropdownContentId);
  triggerButton.setAttribute('aria-haspopup', 'true');

  triggerButton.addEventListener('click', () => {
    if (
      document
        .getElementById(triggerElementId)
        ?.getAttribute('aria-expanded') === 'true'
    ) {
      closeDropdown({
        triggerElementId,
        dropdownContentId,
        onClose,
      });
    } else {
      openDropdown({
        triggerElementId,
        dropdownContentId,
        onClose,
      });
    }
  });

  return {
    closeDropdown: () =>
      closeDropdown({
        triggerElementId,
        dropdownContentId,
        onClose,
      }),
  };
};
