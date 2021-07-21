import { initializeDropdown } from '@utilities/dropdownUtils';

function initializeHomePageFeedPreviewCards() {
  // Select all preview card triggers that haven't already been initialized
  const allPreviewCardTriggers = document.querySelectorAll(
    'button[id^=story-author-preview-trigger]:not([data-initialized])',
  );

  for (const previewTrigger of allPreviewCardTriggers) {
    const dropdownContentId = previewTrigger.getAttribute('aria-controls');
    const dropdownElement = document.getElementById(dropdownContentId);

    if (dropdownElement) {
      initializeDropdown({
        triggerElementId: previewTrigger.id,
        dropdownContentId,
        onOpen: () => dropdownElement?.classList.add('showing'),
        onClose: () => dropdownElement?.classList.remove('showing'),
      });

      previewTrigger.dataset.initialized = true;
    }
  }
}

const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      initializeHomePageFeedPreviewCards();
    }
  });
});

observer.observe(document.getElementById('index-container'), {
  childList: true,
  subtree: true,
});

InstantClick.on('change', () => {
  observer.disconnect();
});

window.addEventListener('beforeunload', () => {
  observer.disconnect();
});

// TODO: init the follow buttons

initializeHomePageFeedPreviewCards();
