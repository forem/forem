import { addSnackbarItem } from '../Snackbar';
import { initializeDropdown } from '@utilities/dropdownUtils';

/* global Runtime  */

const handleCopyPermalink = (closeDropdown) => {
  return (event) => {
    event.preventDefault();
    const permalink = event.target.href;
    Runtime.copyToClipboard(permalink).then(() => {
      addSnackbarItem({ message: 'Copied to clipboard' });
    });
    closeDropdown();
  };
};

const initializeArticlePageDropdowns = () => {
  const dropdownTriggers = document.querySelectorAll(
    'button[id^=comment-dropdown-trigger]',
  );
  for (const dropdownTrigger of dropdownTriggers) {
    if (dropdownTrigger.dataset.initialized) {
      //  Make sure we only initialize once
      continue;
    }

    const dropdownContentId = dropdownTrigger.getAttribute('aria-controls');

    const { closeDropdown } = initializeDropdown({
      triggerElementId: dropdownTrigger.id,
      dropdownContentId,
    });

    // Add actual link location (SEO doesn't like these "useless" links, so adding in here instead of in HTML)
    const dropdownElement = document.getElementById(dropdownContentId);
    const reportAbuseWrapper = dropdownElement.querySelector(
      '.report-abuse-link-wrapper',
    );
    if (reportAbuseWrapper) {
      reportAbuseWrapper.innerHTML = `<a href="${reportAbuseWrapper.dataset.path}" class="crayons-link crayons-link--block">Report abuse</a>`;
    }

    // Initialize the "Copy link" functionality
    dropdownElement
      .querySelector('.permalink-copybtn')
      ?.addEventListener('click', handleCopyPermalink(closeDropdown));

    dropdownTrigger.dataset.initialized = 'true';
  }
};

const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      initializeArticlePageDropdowns();
    }
  });
});
observer.observe(document.getElementById('comment-trees-container'), {
  childList: true,
  subtree: true,
});
InstantClick.on('change', () => {
  observer.disconnect();
});

window.addEventListener('beforeunload', () => {
  observer.disconnect();
});

initializeArticlePageDropdowns();
