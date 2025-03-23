import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';
import { initializeDropdown } from '../utilities/dropdownUtils';
import { setupBillboardInteractivity } from '../utilities/billboardInteractivity';
import { embedGists } from '../utilities/gist';
import { isNativeAndroid, copyToClipboard } from '@utilities/runtime';

// Open in new tab backfill
// We added this behavior on rendering, so this is a backfill for the existing articles
function backfillLinkTarget() {
  const links = document.querySelectorAll('a[href]');
  const appDomain = window.location.hostname;

  links.forEach((link) => {
    const href = link.getAttribute('href');

    if (href && (href.startsWith('http://') || href.startsWith('https://')) && !href.includes(appDomain)) {
      link.setAttribute('target', '_blank');
      
      const existingRel = link.getAttribute('rel');
      const newRelValues = ["noopener", "noreferrer"];

      if (existingRel) {
        const existingRelValues = existingRel.split(" ");
        const mergedRelValues = [...new Set([...existingRelValues, ...newRelValues])].join(" ");
        link.setAttribute('rel', mergedRelValues);
      } else {
        link.setAttribute('rel', newRelValues.join(" "));
      }
    }
  });
}

const fullscreenActionElements = document.getElementsByClassName(
  'js-fullscreen-code-action',
);

if (fullscreenActionElements) {
  addFullScreenModeControl(fullscreenActionElements);
}

const multiReactionDrawerTrigger = document.getElementById(
  'reaction-drawer-trigger',
);

if (
  multiReactionDrawerTrigger &&
  multiReactionDrawerTrigger.dataset.initialized !== 'true'
) {
  initializeDropdown({
    triggerElementId: 'reaction-drawer-trigger',
    dropdownContentId: 'reaction-drawer',
  });
}

// Dropdown accessibility
function hideCopyLinkAnnouncerIfVisible() {
  document.getElementById('article-copy-link-announcer').hidden = true;
}

// Initialize the share options
const shareDropdownButton = document.getElementById('article-show-more-button');

if (shareDropdownButton.dataset.initialized !== 'true') {
  if (isNativeAndroid('shareText')) {
    // Android native apps have enhanced sharing capabilities for Articles and don't use our standard dropdown
    shareDropdownButton.addEventListener('click', () =>
      AndroidBridge.shareText(location.href),
    );
  } else {
    const { closeDropdown } = initializeDropdown({
      triggerElementId: 'article-show-more-button',
      dropdownContentId: 'article-show-more-dropdown',
      onClose: hideCopyLinkAnnouncerIfVisible,
    });

    // We want to close the dropdown on link select (since they open in a new tab)
    document
      .querySelectorAll('#article-show-more-dropdown [href]')
      .forEach((link) => {
        link.addEventListener('click', (event) => {
          closeDropdown(event);
        });
      });
  }

  shareDropdownButton.dataset.initialized = 'true';
}

// Initialize the copy to clipboard functionality
function showAnnouncer() {
  document.getElementById('article-copy-link-announcer').hidden = false;
}

function focusOnComments() {
  if (location.hash === '#comments') {
    //handle focus event on text area
    const element = document.getElementById('text-area');
    const event = new FocusEvent('focus');
    element.dispatchEvent(event);
  }
}

function copyArticleLink() {
  const postUrlValue = document
    .getElementById('copy-post-url-button')
    .getAttribute('data-postUrl');
  copyToClipboard(postUrlValue).then(() => {
    showAnnouncer();
  });
}
document
  .getElementById('copy-post-url-button')
  ?.addEventListener('click', copyArticleLink);

const targetNode = document.querySelector('#comments');
targetNode && embedGists(targetNode);

setupBillboardInteractivity();
focusOnComments();
// Temporary Ahoy Stats for comment section clicks on controls
backfillLinkTarget();
