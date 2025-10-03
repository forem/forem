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

  // Show admin billboard links for admin users
  showAdminBillboardLinks();
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
          // If the event target is the article header and .popover-billboard does not have display none, don't follow that link
          if (event.target.closest('.crayons-article__header') && document.querySelector('.popover-billboard').style.display !== 'none'){
            event.preventDefault();
          }          
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

function showAdminBillboardLinks() {
  // Check if user data is available
  const userDataElement = document.body.dataset.user;
  if (!userDataElement) {
    return;
  }

  try {
    const userData = JSON.parse(userDataElement);
    
    // Check if user is admin
    if (userData.admin) {
      const adminLinks = document.querySelectorAll('.js-admin-billboard-link');
      adminLinks.forEach((link) => {
        link.classList.remove('hidden');
      });
    }
  } catch (error) {
    // Silently handle JSON parsing errors
    console.warn('Error parsing user data for admin billboard links:', error);
  }
}
