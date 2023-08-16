import { initializeDropdown } from '@utilities/dropdownUtils';

/**
 * Initializes each dropdown within each card
 */
const allButtons = document.querySelectorAll('.follow-button');
allButtons.forEach((button) => {
  const { id } = button.dataset;
  initializeDropdown({
    triggerElementId: `options-dropdown-trigger-${id}`,
    dropdownContentId: `options-dropdown-${id}`,
  });
});
