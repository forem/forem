import { initializeDropdown } from './dropdownUtils';

export function setupBillboardDropdown() {
  const sponsorshipDropdownButtons = document.querySelectorAll(
    'button[id^=sponsorship-dropdown-trigger-]',
  );
  if (sponsorshipDropdownButtons.length) {
    sponsorshipDropdownButtons.forEach((sponsorshipDropdownButton) => {
      amendBillboardStyle(sponsorshipDropdownButton);

      const dropdownContentId =
        sponsorshipDropdownButton.getAttribute('aria-controls');
      if (
        sponsorshipDropdownButton &&
        sponsorshipDropdownButton.dataset.initialized !== 'true'
      ) {
        initializeDropdown({
          triggerElementId: sponsorshipDropdownButton.id,
          dropdownContentId,
        });

        sponsorshipDropdownButton.dataset.initialized = 'true';
      }
    });
  }
}

/**
 * If the billboard container height is less than 220px, then we revert the overflow-y property
  given by the billboard class so that the dropdown does not scroll within the container
 */
function amendBillboardStyle(sponsorshipDropdownButton) {
  if (sponsorshipDropdownButton.closest('.js-billboard').clientHeight < 220) {
    sponsorshipDropdownButton.closest('.js-billboard').style.overflowY =
      'revert';
  }
}
