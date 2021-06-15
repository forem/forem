import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';
import { embedGists } from '../utilities/gist';
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

// Pin/Unpin article
// these element are added by initializeBaseUserData.js:addRelevantButtonsToArticle
const toggleArticlePin = async (button) => {
  const isPinButton = button.id === 'js-pin-article';
  const { articleId, path } = button.dataset;
  const method = isPinButton ? 'PUT' : 'DELETE';
  const body = method === 'PUT' ? JSON.stringify({ id: articleId }) : null;

  const response = await fetch(path, {
    method,
    body,
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  });

  // response could potentially fail if the article is draft but we don't show
  // the buttons in those cases, so I think there's no need to handle that scenario client side
  if (response.ok) {
    // replace id and label
    button.id = isPinButton ? 'js-unpin-article' : 'js-pin-article';
    button.innerHTML = `${isPinButton ? 'Unpin' : 'Pin'} Post`;

    const message = isPinButton
      ? 'The post has been succesfully pinned'
      : 'The post has been succesfully unpinned';
    addSnackbarItem({ message });
  }
};

const actionsContainer = document.getElementById('action-space');
const pinTargets = ['js-pin-article', 'js-unpin-article'];
actionsContainer.addEventListener('click', async (event) => {
  if (pinTargets.includes(event.target.id)) {
    toggleArticlePin(event.target);
  }
});

const targetNode = document.querySelector('#comments');
targetNode && embedGists(targetNode);
