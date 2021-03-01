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

const userDataIntervalID = setInterval(async () => {
  const { user = null, userStatus } = document.body.dataset;

  if (userStatus === 'logged-out') {
    // User is not logged on so nothing dynamic to add to the page.
    clearInterval(userDataIntervalID);
    return;
  }

  if (userStatus === 'logged-in' && user !== null) {
    // Load the comment subscription button for logged on users.
    clearInterval(userDataIntervalID);
    const root = document.getElementById('comment-subscription');

    try {
      const {
        getCommentSubscriptionStatus,
        setCommentSubscriptionStatus,
        CommentSubscription,
      } = await import('../CommentSubscription');

      const { articleId } = document.getElementById('article-body').dataset;
      const { config: subscriptionType } = await getCommentSubscriptionStatus(
        articleId,
      );
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
        />,
        root,
      );
    } catch (e) {
      document.getElementById('comment-subscription').innerHTML =
        '<p className="color-accent-danger">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
    }
  }
});
