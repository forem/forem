import { h, render } from 'preact';
import { Snackbar } from '../Snackbar';

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');

render(<Snackbar lifespan="3" />, snackZone, snackZone.firstElementChild);

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
        getSubscriptionStatus,
        setSubscription,
        CommentSubscription,
      } = await import('../CommentSubscription');

      const { articleId } = document.querySelector('#article-body').dataset;
      const { config: subscriptionType } = await getSubscriptionStatus(
        articleId,
      );
      const subscriptionRequestHandler = (type) =>
        setSubscription(articleId, type);

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
        '<p style="color: rgb(220, 24, 24);">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
    }
  }
});
