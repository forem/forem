import { showSnackbar } from '../utilities/showSnackbar';
import {
  initializeDropdown,
  getDropdownRepositionListener,
} from '@utilities/dropdownUtils';
import { locale } from '@utilities/locale';
import { copyToClipboard } from '@utilities/runtime';

const handleCopyPermalink = (closeDropdown) => {
  return (event) => {
    event.preventDefault();
    const permalink = event.target.href;
    copyToClipboard(permalink).then(() => {
      showSnackbar('Copied to clipboard');
    });
    closeDropdown();
  };
};

const initializeArticlePageDropdowns = () => {
  // Gather all dropdown triggers for comment options and profile previews
  const dropdownTriggers = document.querySelectorAll(
    'button[id^=comment-dropdown-trigger], button[id^=comment-profile-preview-trigger-], button[id^=toggle-comments-sort-dropdown]',
  );

  for (const dropdownTrigger of dropdownTriggers) {
    if (dropdownTrigger.dataset.initialized) {
      //  Make sure we only initialize once
      continue;
    }

    const isProfilePreview = dropdownTrigger.id.includes(
      'comment-profile-preview-trigger',
    );

    const dropdownContentId = dropdownTrigger.getAttribute('aria-controls');
    const dropdownElement = document.getElementById(dropdownContentId);

    if (dropdownElement) {
      const { closeDropdown } = initializeDropdown({
        triggerElementId: dropdownTrigger.id,
        dropdownContentId,
        onOpen: () => {
          if (isProfilePreview) {
            dropdownElement?.classList.add('showing');
          }
        },
        onClose: () => {
          if (isProfilePreview) {
            dropdownElement?.classList.remove('showing');
          }
        },
      });

      // Add actual link location (SEO doesn't like these "useless" links, so adding in here instead of in HTML)
      const reportAbuseWrapper = dropdownElement.querySelector(
        '.report-abuse-link-wrapper',
      );
      if (reportAbuseWrapper) {
        reportAbuseWrapper.innerHTML = `<a href="${
          reportAbuseWrapper.dataset.path
        }" class="crayons-link crayons-link--block">${locale(
          'core.report_abuse',
        )}</a>`;
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
  const {
    jsCommentUserId: commentUserId,
    jsDropdownContentId: dropdownContentId,
  } = placeholderElement.dataset;
  const response = await window.fetch(
    `/profile_preview_cards/${commentUserId}`,
  );
  const htmlContent = await response.text();

  const generatedElement = document.createElement('div');
  generatedElement.innerHTML = htmlContent;

  const { firstElementChild: previewCard } = generatedElement;
  previewCard.id = dropdownContentId;

  placeholderElement.parentNode.replaceChild(previewCard, placeholderElement);
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

// Preview card dropdowns reposition on scroll
const dropdownRepositionListener = getDropdownRepositionListener();
document.addEventListener('scroll', dropdownRepositionListener);

InstantClick.on('change', () => {
  observer.disconnect();
  document.removeEventListener('scroll', dropdownRepositionListener);
});

window.addEventListener('beforeunload', () => {
  observer.disconnect();
  document.removeEventListener('scroll', dropdownRepositionListener);
});

initializeArticlePageDropdowns();
