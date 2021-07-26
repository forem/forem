import { h, render, Fragment } from 'preact';
import { initializeDropdown } from '@utilities/dropdownUtils';

const UserMetadata = ({
  email,
  location,
  summary,
  created_at,
  education,
  employment_title,
  employer_name,
  employer_url,
}) => {
  const joinedOnDate = new Date(created_at);
  const joinedOnDateString = joinedOnDate.toLocaleString(undefined, {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  return (
    <Fragment>
      {summary && <div className="color-base-70">{summary}</div>}
      <div className="user-metadata-details">
        <ul class="user-metadata-details-inner">
          {email && (
            <li>
              <div class="key">Email</div>
              <div class="value">
                <a href={`mailto:${email}`}>{email}</a>
              </div>
            </li>
          )}
          {employment_title && (
            <li>
              <div className="key">Work</div>
              <div className="value">
                {employment_title}
                {employer_name && <span class="opacity-50"> at </span>}
                {employer_name && employer_url && (
                  <a
                    href={employer_url}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {employer_name}
                  </a>
                )}
                {!employer_url && employer_name}
              </div>
            </li>
          )}
          {location && (
            <li>
              <div class="key">Location</div>
              <div class="value">{location}</div>
            </li>
          )}
          {education && (
            <li>
              <div class="key">Education</div>
              <div class="value">{education}</div>
            </li>
          )}
          <li>
            <div class="key">Joined</div>
            <div class="value">
              <time datetime={created_at} class="date">
                {joinedOnDateString}
              </time>
            </div>
          </li>
        </ul>
      </div>
    </Fragment>
  );
};

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

  // TODO: get all the matching placeholders, not just the hovered ones

  render(
    <UserMetadata {...authorMetadata} />,
    metadataPlaceholder.parentElement,
    metadataPlaceholder,
  );

  metadataPlaceholder.parentElement.parentElement.style.setProperty(
    '--card-color',
    authorMetadata.card_color,
  );

  metadataPlaceholder.remove();
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

// TODO: init the follow buttons

initializeFeedPreviewCards();
listenForHoveredOrFocusedStoryCards();
