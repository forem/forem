import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { initializeUserSubscriptionLiquidTagContent } from '../liquidTags/userSubscriptionLiquidTag';

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');
if (snackZone) {
  render(<Snackbar lifespan={3} />, snackZone);
}

// eslint-disable-next-line no-restricted-globals
top.addSnackbarItem = addSnackbarItem;


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

initializeUserSubscriptionLiquidTagContent();
