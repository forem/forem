import { h, render } from 'preact';
import { UserMetadata } from '../profilePreviewCards/UserMetadata';
import {
  initializeDropdown,
  getDropdownRepositionListener,
} from '@utilities/dropdownUtils';
import { request } from '@utilities/http/request';

const cachedAuthorMetadata = {};

async function populateMissingMetadata(metadataPlaceholder) {
  const { authorId, fetched } = metadataPlaceholder.dataset;

  // If the metadata is already being fetched, do nothing
  if (fetched) {
    return;
  }
  metadataPlaceholder.dataset.fetched = 'true';

  const previouslyFetchedAuthorMetadata = cachedAuthorMetadata[authorId];

  if (previouslyFetchedAuthorMetadata) {
    renderMetadata(previouslyFetchedAuthorMetadata, metadataPlaceholder);
  } else {
    const response = await request(`/profile_preview_cards/${authorId}`);
    const authorMetadata = await response.json();

    cachedAuthorMetadata[authorId] = authorMetadata;
    renderMetadata(authorMetadata, metadataPlaceholder);
  }
}

function renderMetadata(metadata, placeholder) {
  const container = placeholder.parentElement;

  render(<UserMetadata {...metadata} />, container, placeholder);

  container
    .closest('.profile-preview-card__content')
    .style.setProperty('--card-color', metadata.card_color);
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

export function listenForHoveredOrFocusedStoryCards() {
  const mainContent = document.getElementById('main-content');

  mainContent.addEventListener('mouseover', checkForPreviewCardDetails);
  mainContent.addEventListener('focusin', checkForPreviewCardDetails);
}

export function initializeFeedPreviewCards() {
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

if (document.getElementById('index-container')) {
  observer.observe(document.getElementById('index-container'), {
    childList: true,
    subtree: true,
  });
}

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
