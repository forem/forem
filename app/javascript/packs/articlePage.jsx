import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';
import { embedGists } from '../utilities/gist';
import {
  initializeDropdown,
  getDropdownRepositionListener,
} from '../utilities/dropdownUtils';
import { getInstantClick } from '../topNavigation/utilities';

/* global Runtime */

const fullscreenActionElements = document.getElementsByClassName(
  'js-fullscreen-code-action',
);

if (fullscreenActionElements) {
  addFullScreenModeControl(fullscreenActionElements);
}

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');
if (snackZone) {
  render(<Snackbar lifespan="3" />, snackZone);
}

// eslint-disable-next-line no-restricted-globals
top.addSnackbarItem = addSnackbarItem;

// Dropdown accessibility
function hideCopyLinkAnnouncerIfVisible() {
  document.getElementById('article-copy-link-announcer').hidden = true;
}

// Initialize the share options
const shareDropdownButton = document.getElementById('article-show-more-button');

if (shareDropdownButton.dataset.initialized !== 'true') {
  if (Runtime.isNativeAndroid('shareText')) {
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

function copyArticleLink() {
  const postUrlValue = document
    .getElementById('copy-post-url-button')
    .getAttribute('data-postUrl');
  Runtime.copyToClipboard(postUrlValue).then(() => {
    showAnnouncer();
  });
}
document
  .getElementById('copy-post-url-button')
  ?.addEventListener('click', copyArticleLink);

// Comment Subscription
getCsrfToken().then(async () => {
  const { user = null, userStatus } = document.body.dataset;
  const root = document.getElementById('comment-subscription');
  const isLoggedIn = userStatus === 'logged-in';

  try {
    const {
      getCommentSubscriptionStatus,
      setCommentSubscriptionStatus,
      CommentSubscription,
    } = await import('../CommentSubscription');

    const { articleId } = document.getElementById('article-body').dataset;

    let subscriptionType = 'not_subscribed';

    if (isLoggedIn && user !== null) {
      ({ config: subscriptionType } = await getCommentSubscriptionStatus(
        articleId,
      ));
    }

    const subscriptionRequestHandler = async (type) => {
      const message = await setCommentSubscriptionStatus(articleId, type);

      addSnackbarItem({ message, addCloseButton: true });
    };

    render(
      <CommentSubscription
        subscriptionType={subscriptionType}
        positionType="static"
        onSubscribe={subscriptionRequestHandler}
        onUnsubscribe={subscriptionRequestHandler}
        isLoggedIn={isLoggedIn}
      />,
      root,
    );
  } catch (e) {
    document.getElementById('comment-subscription').innerHTML =
      '<p className="color-accent-danger">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
  }
});

// Initialize the profile preview functionality
const profilePreviewTrigger = document.getElementById(
  'profile-preview-trigger',
);

const dropdownContent = document.getElementById('profile-preview-content');

if (profilePreviewTrigger?.dataset.initialized !== 'true') {
  initializeDropdown({
    triggerElementId: 'profile-preview-trigger',
    dropdownContentId: 'profile-preview-content',
    onOpen: () => {
      dropdownContent?.classList.add('showing');
    },
    onClose: () => {
      dropdownContent?.classList.remove('showing');
    },
  });

  profilePreviewTrigger.dataset.initialized = 'true';
}

const targetNode = document.querySelector('#comments');
targetNode && embedGists(targetNode);

// Preview card dropdowns reposition on scroll
const dropdownRepositionListener = getDropdownRepositionListener();

document.addEventListener('scroll', dropdownRepositionListener);

getInstantClick().then((ic) => {
  ic.on('change', () => {
    document.removeEventListener('scroll', dropdownRepositionListener);
  });
});

window.addEventListener('beforeunload', () => {
  document.removeEventListener('scroll', dropdownRepositionListener);
});
