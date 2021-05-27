import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';
import { initializeDropdown } from '@utilities/dropdownUtils';

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
      .forEach((link) => link.addEventListener('click', closeDropdown));
  }
  shareDropdownButton.dataset.initialized = 'true';
}

// Initialize the copy to clipboard functionality
function showAnnouncer() {
  const { activeElement } = document;
  const input =
    activeElement.localName === 'clipboard-copy'
      ? activeElement.querySelector('input')
      : document.getElementById('article-copy-link-input');
  input.focus();
  input.setSelectionRange(0, input.value.length);

  document.getElementById('article-copy-link-announcer').hidden = false;
}

function copyArticleLink() {
  const inputValue = document.getElementById('article-copy-link-input').value;
  Runtime.copyToClipboard(inputValue).then(() => {
    showAnnouncer();
  });
}
document
  .querySelector('clipboard-copy')
  ?.addEventListener('click', copyArticleLink);

const userDataIntervalID = setInterval(async () => {
  const { user = null, userStatus } = document.body.dataset;

  clearInterval(userDataIntervalID);
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
