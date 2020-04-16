import { h, render } from 'preact';
import { CommentSubscription } from '../CommentSubscription/CommentSubscription';
import { request } from '../utilities/request';

// TODO: Dynamic import only when user is logged on.

const root = document.getElementById('comment-subscription');
const { articleId } = document.getElementById('article-body').dataset;

const getSubscriptionStatus = async () => {
  try {
    const response = await request(
      `/notification_subscriptions/Article/${articleId}`,
    );

    const subscriptionStatus = await response.json();

    return subscriptionStatus;
  } catch (error) {
    return new Error('An error occurred, please try again');
  }
};

const subscriptionRequestHandler = async (subscriptionType) => {
  try {
    const response = await request(
      `/notification_subscriptions/Article/${articleId}`,
      {
        method: 'POST',
        body: JSON.stringify({ config: subscriptionType }),
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

setTimeout(async () => {
  const { config: subscriptionType } = await getSubscriptionStatus();

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
}, 0);
