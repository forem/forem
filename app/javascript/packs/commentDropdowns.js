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
    // TODO: there's a brief moment where the trigger exists but the dropdown content doesn't, and we get an error here
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

const fetchMissingProfilePreviewCard = async (element) => {
  window
    .fetch(
      `/profile_preview_card/show?userid=${element.dataset.jsCommentUserId}&preview_card_id=${element.dataset.jsDropdownContentId}`,
    )
    .then((res) => res.text())
    .then((response) => {
      const generatedElement = document.createElement('div');
      generatedElement.innerHTML = response;
      element.parentNode.replaceChild(
        generatedElement.firstElementChild,
        element,
      );
      // Make sure the button inside the dropdown is initialized
      initializeAllFollowButts();
    });
};

const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      let profilePreviewMutation;

      mutation.addedNodes.forEach((node) => {
        if (
          node.nodeType === Node.ELEMENT_NODE &&
          node.getElementsByClassName('preview-card-placeholder')[0]
        ) {
          profilePreviewMutation = node.getElementsByClassName(
            'preview-card-placeholder',
          )[0];
        }
      });

      if (profilePreviewMutation) {
        fetchMissingProfilePreviewCard(profilePreviewMutation);
      }

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
