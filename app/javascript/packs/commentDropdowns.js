import { addSnackbarItem } from '../Snackbar';
import { initializeDropdown } from '@utilities/dropdownUtils';

/* global Runtime initializeAllFollowButts  */

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
  // Gather all dropdown triggers for comment options and profile previews
  const dropdownTriggers = document.querySelectorAll(
    'button[id^=comment-dropdown-trigger], button[id^=comment-profile-preview-trigger-]',
  );

  for (const dropdownTrigger of dropdownTriggers) {
    if (dropdownTrigger.dataset.initialized) {
      //  Make sure we only initialize once
      continue;
    }

    const dropdownContentId = dropdownTrigger.getAttribute('aria-controls');
    const dropdownElement = document.getElementById(dropdownContentId);

    if (dropdownElement) {
      const { closeDropdown } = initializeDropdown({
        triggerElementId: dropdownTrigger.id,
        dropdownContentId,
      });

      // Add actual link location (SEO doesn't like these "useless" links, so adding in here instead of in HTML)
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

      dropdownTrigger.dataset.initialized = true;
    }
  }
};

/**
 * Function to retrieve the Profile Preview Card for newly added comments, and asynchronously replace the placeholder
 *
 * @param {HTMLElement} placeholderElement The <span> placeholder element to be replaced by the preview dropdown
 */
const fetchMissingProfilePreviewCard = async (placeholderElement) => {
  const response = await window.fetch(
    `/profile_preview_card/show?user_id=${placeholderElement.dataset.jsCommentUserId}&preview_card_id=${placeholderElement.dataset.jsDropdownContentId}`,
  );
  const htmlContent = await response.text();

  const generatedElement = document.createElement('div');
  generatedElement.innerHTML = htmlContent;

  placeholderElement.parentNode.replaceChild(
    generatedElement.firstElementChild,
    placeholderElement,
  );

  // Make sure the button inside the dropdown is initialized
  initializeAllFollowButts();
};

/**
 * When a new comment is added to a discussion, the preview card dropdown must be dynamically fetched.
 * This function detects if a preview card placeholder has been added in a given mutation and initiates the profile card fetch.
 **/
const checkMutationForProfilePreviewCardPlaceholder = (mutation) => {
  mutation.addedNodes.forEach((node) => {
    if (node.nodeType === Node.ELEMENT_NODE) {
      const placeholder = node.getElementsByClassName(
        'preview-card-placeholder',
      )[0];
      if (placeholder) {
        fetchMissingProfilePreviewCard(placeholder);
      }
    }
  });
};

const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      checkMutationForProfilePreviewCardPlaceholder(mutation);
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
