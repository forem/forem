import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';
import { initializeDropdown } from '../utilities/dropdownUtils';
import { setupBillboardInteractivity } from '../utilities/billboardInteractivity';
import { embedGists } from '../utilities/gist';
import { initializeUserSubscriptionLiquidTagContent } from '../liquidTags/userSubscriptionLiquidTag';
import { trackCommentClicks } from '@utilities/ahoy/trackEvents';
import { isNativeAndroid, copyToClipboard } from '@utilities/runtime';

const animatedImages = document.querySelectorAll('[data-animated="true"]');
if (animatedImages.length > 0) {
  import('@utilities/animatedImageUtils').then(
    ({ initializePausableAnimatedImages }) => {
      initializePausableAnimatedImages(animatedImages);
    },
  );
}

const fullscreenActionElements = document.getElementsByClassName(
  'js-fullscreen-code-action',
);

if (fullscreenActionElements) {
  addFullScreenModeControl(fullscreenActionElements);
}

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');
if (snackZone) {
  render(<Snackbar lifespan={3} />, snackZone);
}

// eslint-disable-next-line no-restricted-globals
top.addSnackbarItem = addSnackbarItem;

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

// Comment Subscription
getCsrfToken().then(async () => {
  const { user = null, userStatus } = document.body.dataset;
  const root = document.getElementById('comment-subscription');
  const isLoggedIn = userStatus === 'logged-in';

  if (!root) {
    return;
  }
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
    root.innerHTML =
      '<p className="color-accent-danger">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
  }
});

const targetNode = document.querySelector('#comments');
targetNode && embedGists(targetNode);

setupBillboardInteractivity();
initializeUserSubscriptionLiquidTagContent();
focusOnComments();
// Temporary Ahoy Stats for comment section clicks on controls
trackCommentClicks('comments');
