import {
  initializeDropdown,
  getDropdownRepositionListener,
} from '@utilities/dropdownUtils';
import { request } from '@utilities/http/request';

const cachedAuthorMetadata = {};

function createMetadataItem(label, valueNodeOrText) {
  const li = document.createElement('li');

  const keyDiv = document.createElement('div');
  keyDiv.className = 'key';
  keyDiv.textContent = label;

  const valueDiv = document.createElement('div');
  valueDiv.className = 'value';
  if (valueNodeOrText instanceof Node) {
    valueDiv.appendChild(valueNodeOrText);
  } else {
    valueDiv.textContent = valueNodeOrText;
  }

  li.appendChild(keyDiv);
  li.appendChild(valueDiv);
  return li;
}

export function buildUserMetadataFragment({
  email,
  location,
  summary,
  created_at: createdAt,
  education,
  work,
}) {
  const fragment = document.createDocumentFragment();

  if (summary) {
    const summaryDiv = document.createElement('div');
    summaryDiv.className = 'color-base-70';
    summaryDiv.textContent = summary;
    fragment.appendChild(summaryDiv);
  }

  const detailsDiv = document.createElement('div');
  detailsDiv.className = 'user-metadata-details';

  const ul = document.createElement('ul');
  ul.className = 'user-metadata-details-inner';

  if (email) {
    const emailLink = document.createElement('a');
    emailLink.href = `mailto:${email}`;
    emailLink.textContent = email;
    ul.appendChild(createMetadataItem('Email', emailLink));
  }

  if (work) {
    ul.appendChild(createMetadataItem('Work', work));
  }

  if (location) {
    ul.appendChild(createMetadataItem('Location', location));
  }

  if (education) {
    ul.appendChild(createMetadataItem('Education', education));
  }

  const joinedOnDate = new Date(createdAt);
  const joinedOnDateString = new Intl.DateTimeFormat(
    navigator.language || 'default',
    {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    },
  ).format(joinedOnDate);

  const timeEl = document.createElement('time');
  timeEl.setAttribute('datetime', createdAt);
  timeEl.className = 'date';
  timeEl.textContent = joinedOnDateString;
  ul.appendChild(createMetadataItem('Joined', timeEl));

  detailsDiv.appendChild(ul);
  fragment.appendChild(detailsDiv);

  return fragment;
}

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

  placeholder.replaceWith(buildUserMetadataFragment(metadata));

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

window.InstantClick?.on('change', () => {
  observer.disconnect();
  document.removeEventListener('scroll', dropdownRepositionListener);
});

window.addEventListener('beforeunload', () => {
  observer.disconnect();
  document.removeEventListener('scroll', dropdownRepositionListener);
});
