import { h, render } from 'preact';
import {
  CommentSubscription,
  COMMENT_SUBSCRIPTION_TYPE,
} from '../CommentSubscription/CommentSubscription';
import { getContentOfToken } from '../onboarding/utilities';

// TODO: Dynamic import only when user is logged on.

const root = document.getElementById('comment-subscription');
const { articleId } = document.getElementById('article-body').dataset;

const subscriptionRequestHandler = async (subscriptionType) => {
  try {
    const csrfToken = await getContentOfToken('csrf-token');
    const response = await fetch(
      `/notification_subscriptions/Article/${articleId}`,
      {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ config: subscriptionType }),
        credentials: 'same-origin',
      },
    );

    // true means you're subscribed, false means unsubscribed
    const subscribed = await response.json();

    let message = 'You have been unsubscribed from comments for this article';

    if (subscribed) {
      message = `You have been subscribed to ${subscriptionType.replace(
        /_/g,
        ' ',
      )}`;
    }

    alert(message);
  } catch (error) {
    alert('An error occurred, please try again');
  }
};

const someSubscriptionType = COMMENT_SUBSCRIPTION_TYPE.TOP;

render(
  <CommentSubscription
    subscriptionType={someSubscriptionType}
    positionType="static"
    onSubscribe={subscriptionRequestHandler}
    onUnsubscribe={subscriptionRequestHandler}
  />,
  root,
  root.firstElementChild,
);
