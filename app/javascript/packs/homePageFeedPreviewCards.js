import { initializeDropdown } from '@utilities/dropdownUtils';

function initializeHomePageFeedPreviewCards() {
  const allPreviewCardTriggers = document.querySelectorAll(
    'button[id^=story-author-preview-trigger]',
  );
  for (const previewTrigger of allPreviewCardTriggers) {
    if (previewTrigger.dataset.initialized) {
      //  Make sure we only initialize once
      continue;
    }

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

initializeHomePageFeedPreviewCards();
