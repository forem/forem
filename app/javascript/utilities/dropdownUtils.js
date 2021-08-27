import { isInViewport } from '@utilities/viewport';
import { debounceAction } from '@utilities/debounceAction';

/**
 * Helper function designed to be used on scroll to detect when dropdowns should switch from dropping downwards/upwards.
 * The action is debounced since scroll events are usually fired several at a time.
 *
 * @returns {Function} a debounced function that handles the repositioning of dropdowns
 * @example
 *
 * document.addEventListener('scroll', getDropdownRepositionListener());
 */
export const getDropdownRepositionListener = () =>
  debounceAction(handleDropdownRepositions);

/**
 * Checks for all dropdowns on the page which have the attribute 'data-repositioning-dropdown', signalling
 * they should dynamically change between dropping downwards or upwards, depending on viewport position.
 *
 * Any dropdowns not fully in view when dropping down will be switched to dropping upwards.
 */
const handleDropdownRepositions = () => {
  // Select all of the dropdowns which should reposition
  const allRepositioningDropdowns = document.querySelectorAll(
    '[data-repositioning-dropdown]',
  );

  for (const element of allRepositioningDropdowns) {
    // Default to dropping downwards
    element.classList.remove('reverse');

    const isDropdownCurrentlyOpen = element.style.display === 'block';

    if (!isDropdownCurrentlyOpen) {
      // We can't determine position on an element with display:none, so we "show" the dropdown with 0 opacity very temporarily
      element.style.opacity = 0;
      element.style.display = 'block';
    }

    if (!isInViewport({ element })) {
      // If the element isn't fully visible when dropping down, reverse the direction
      element.classList.add('reverse');
    }

    if (!isDropdownCurrentlyOpen) {
      // Revert the temporary changes to determine position
      element.style.removeProperty('display');
      element.style.removeProperty('opacity');
    }
  }
};

/**
 * Helper query string to identify interactive/focusable HTML elements
 */
const INTERACTIVE_ELEMENTS_QUERY =
  'button, [href], input:not([type="hidden"]), select, textarea, [tabindex="0"]';

/**
 * Open the given dropdown, updating aria attributes, and focusing the first interactive element
 *
 * @param {Object} args
 * @param {string} args.triggerElementId The id of the button which activates the dropdown
 * @param {string} args.dropdownContent The id of the dropdown content element
 */
const openDropdown = ({ triggerElementId, dropdownContentId }) => {
  const dropdownContent = document.getElementById(dropdownContentId);
  const triggerElement = document.getElementById(triggerElementId);

  triggerElement.setAttribute('aria-expanded', 'true');

  // Style set inline to prevent specificity issues
  dropdownContent.style.display = 'block';

  // Send focus to the first suitable element
  dropdownContent.querySelector(INTERACTIVE_ELEMENTS_QUERY)?.focus();
};

/**
 * Close the given dropdown, updating aria attributes
 *
 * @param {Object} args
 * @param {string} args.triggerElementId The id of the button which activates the dropdown
 * @param {string} args.dropdownContent The id of the dropdown content element
 * @param {Function} args.onClose Optional function for any side-effects which should occur on dropdown close
 */
const closeDropdown = ({ triggerElementId, dropdownContentId, onClose }) => {
  const dropdownContent = document.getElementById(dropdownContentId);

  if (!dropdownContent) {
    // Component may have unmounted
    return;
  }

  document
    .getElementById(triggerElementId)
    ?.setAttribute('aria-expanded', 'false');

  // Remove the inline style added when we opened the dropdown
  dropdownContent.style.removeProperty('display');

  onClose?.();
};

/**
 * A helper function to initialize dropdown behaviors. This function attaches open/close click and keyup listeners,
 * and makes sure relevant aria properties and keyboard focus are updated.
 *
 * @param {Object} args
 * @param {string} args.triggerButtonElementId The ID of the button which triggers the dropdown open/close behavior
 * @param {string} args.dropdownContentId The ID of the dropdown content which should open/close on trigger button press
 * @param {string} args.dropdownContentCloseButtonId Optional ID of any button within the dropdown content which should close the dropdown
 * @param {Function} args.onClose An optional callback for when the dropdown is closed. This can be passed to execute any side-effects required when the dropdown closes.
 * @param {Function} args.onOpen An optional callback for when the dropdown is opened. This can be passed to execute any side-effects required when the dropdown opens.
 *
 * @returns {{closeDropdown: Function}} Object with callback to close the initialized dropdown
 */
export const initializeDropdown = ({
  triggerElementId,
  dropdownContentId,
  dropdownContentCloseButtonId,
  onClose,
  onOpen,
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

  const keyUpListener = ({ key }) => {
    if (key === 'Escape') {
      // Close the dropdown and return focus to the trigger button to prevent focus being lost
      const isCurrentlyOpen =
        triggerButton.getAttribute('aria-expanded') === 'true';
      if (isCurrentlyOpen) {
        closeDropdown({
          triggerElementId,
          dropdownContentId,
          onClose: onCloseCleanupActions,
        });
        triggerButton.focus();
      }
    } else if (key === 'Tab') {
      // Close the dropdown if the user has tabbed away from it
      const isInsideDropdown = dropdownContent?.contains(
        document.activeElement,
      );
      if (!isInsideDropdown) {
        closeDropdown({
          triggerElementId,
          dropdownContentId,
          onClose: onCloseCleanupActions,
        });
      }
    }
  };

  // Close the dropdown if user has clicked outside
  const clickOutsideListener = ({ target }) => {
    if (
      target !== triggerButton &&
      !dropdownContent.contains(target) &&
      !triggerButton.contains(target)
    ) {
      closeDropdown({
        triggerElementId,
        dropdownContentId,
        onClose: onCloseCleanupActions,
      });

      // If the user did not click on another interactive item, return focus to the trigger
      if (!target.matches(INTERACTIVE_ELEMENTS_QUERY)) {
        triggerButton.focus();
      }
    }
  };

  // Any necessary side effects required on dropdown close
  const onCloseCleanupActions = () => {
    onClose?.();
    document.removeEventListener('keyup', keyUpListener);
    document.removeEventListener('click', clickOutsideListener);
  };

  // Add the main trigger button toggle funcationality
  triggerButton.addEventListener('click', () => {
    if (
      document
        .getElementById(triggerElementId)
        ?.getAttribute('aria-expanded') === 'true'
    ) {
      closeDropdown({
        triggerElementId,
        dropdownContentId,
        onClose: onCloseCleanupActions,
      });
    } else {
      openDropdown({
        triggerElementId,
        dropdownContentId,
      });
      onOpen?.();

      document.addEventListener('keyup', keyUpListener);
      document.addEventListener('click', clickOutsideListener);
    }
  });

  if (dropdownContentCloseButtonId) {
    // The dropdown content has a 'close' button inside that we also need to handle
    document
      .getElementById(dropdownContentCloseButtonId)
      ?.addEventListener('click', () => {
        closeDropdown({
          triggerElementId,
          dropdownContentId,
          onClose: onCloseCleanupActions,
        });

        document.getElementById(triggerElementId)?.focus();
      });
  }

  return {
    closeDropdown: () => {
      closeDropdown({
        triggerElementId,
        dropdownContentId,
        onClose: onCloseCleanupActions,
      });
    },
  };
};
