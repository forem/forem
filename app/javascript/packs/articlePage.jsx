import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');

render(<Snackbar lifespan="3" />, snackZone);

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
    const root = document.querySelector('#comment-subscription');

    try {
      const {
        getCommentSubscriptionStatus,
        setCommentSubscriptionStatus,
        CommentSubscription,
      } = await import('../CommentSubscription');

      const { articleId } = document.querySelector('#article-body').dataset;
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
        root.firstElementChild,
      );
    } catch (e) {
      document.querySelector('#comment-subscription').innerHTML =
        '<p className="color-accent-danger">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
    }
  }
});
