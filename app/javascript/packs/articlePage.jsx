import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';

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

// Pin/Unpin article
// these element are added by initializeBaseUserData.js:addRelevantButtonsToArticle
const toggleArticlePin = async (button) => {
  const isPinButton = button.id === 'js-pin-article';

  const response = await fetch(button.dataset.action, {
    method: isPinButton ? 'POST' : 'DELETE',
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

// Comment Subscription
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
