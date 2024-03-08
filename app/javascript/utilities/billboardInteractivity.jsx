import { initializeDropdown } from './dropdownUtils';

export function setupBillboardInteractivity() {
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

      const popoverParent =
        sponsorshipDropdownButton.closest('.popover-billboard');
      if (
        popoverParent &&
        sponsorshipDropdownButton.getBoundingClientRect().top >
          window.innerHeight / 2
      ) {
        popoverParent.classList.add('popover-billboard--menuopenupwards');
      }
    });
  }
  const sponsorshipCloseButtons = document.querySelectorAll(
    'button[id^=sponsorship-close-trigger-]',
  );
  if (sponsorshipCloseButtons.length) {
    sponsorshipCloseButtons.forEach((sponsorshipCloseButton) => {
      sponsorshipCloseButton.addEventListener('click', () => {
        dismissBillboard(sponsorshipCloseButton);
      });
      if (sponsorshipCloseButton.closest('.popover-billboard')) {
        document.addEventListener('click', (event) => {
          if (!event.target.closest('.js-billboard')) {
            dismissBillboard(sponsorshipCloseButton);
          }
        });
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

function dismissBillboard(sponsorshipCloseButton) {
  const sku =
    sponsorshipCloseButton.closest('.js-billboard').dataset.dismissalSku;
  sponsorshipCloseButton.closest('.js-billboard').style.display = 'none';
  if (localStorage && sku && sku.length > 0) {
    const skuArray =
      JSON.parse(localStorage.getItem('dismissal_skus_triggered')) || [];
    if (!skuArray.includes(sku)) {
      skuArray.push(sku);
      localStorage.setItem(
        'dismissal_skus_triggered',
        JSON.stringify(skuArray),
      );
    }
  }
}
