import { initializeDropdown } from './dropdownUtils';

export function setupBillboardDropdown() {
  const sponsorshipDropdownButtons = document.querySelectorAll(
    'button[id^=sponsorship-dropdown-trigger-]',
  );
  if (sponsorshipDropdownButtons.length) {
    sponsorshipDropdownButtons.forEach((sponsorshipDropdownButton) => {
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
