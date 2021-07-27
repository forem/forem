import { h, render } from 'preact';
import { UserMetadata } from '../profilePreviewCards/UserMetadata';
import { initializeDropdown } from '@utilities/dropdownUtils';

async function populateMissingMetadata(metadataPlaceholder) {
  const { authorId } = metadataPlaceholder.dataset;
  const response = await fetch(`/profile_preview_cards/${authorId}`, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  });
  const authorMetadata = await response.json();

  // A given author may have multiple cards in the feed - populate their metadata everywhere it is missing
  const allPlaceholdersForThisAuthor = document.querySelectorAll(
    `.author-preview-metadata-container[data-author-id="${authorId}"]`,
  );

  for (const placeholder of allPlaceholdersForThisAuthor) {
    render(
      <UserMetadata {...authorMetadata} />,
      placeholder.parentElement,
      placeholder,
    );

    placeholder.parentElement.parentElement.style.setProperty(
      '--card-color',
      authorMetadata.card_color,
    );

    placeholder.remove();
  }
}

function checkForPreviewCardDetails(event) {
  const { target } = event;

  if (target.classList.contains('profile-preview-card__trigger')) {
    const metadataPlaceholder = target.parentElement.getElementsByClassName(
      'author-preview-metadata-container',
    )[0];

    if (metadataPlaceholder) {
      // User is within one of the story cards - and the metadata has not been fetched yet
      populateMissingMetadata(metadataPlaceholder);
    }
  }
}

function listenForHoveredOrFocusedStoryCards() {
  document
    .getElementById('main-content')
    .addEventListener('mouseover', checkForPreviewCardDetails);

  document
    .getElementById('main-content')
    .addEventListener('focusin', checkForPreviewCardDetails);
}

function initializeFeedPreviewCards() {
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
      initializeFeedPreviewCards();
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

initializeFeedPreviewCards();
listenForHoveredOrFocusedStoryCards();
