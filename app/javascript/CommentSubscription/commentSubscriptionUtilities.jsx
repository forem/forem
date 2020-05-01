import { request } from '../utilities/http/request';
import { addSnackbarItem } from '../Snackbar';

export async function getSubscriptionStatus(articleId) {
  try {
    const response = await request(
      `/notification_subscriptions/Article/${articleId}`,
    );

    const subscriptionStatus = await response.json();

    return subscriptionStatus;
  } catch (error) {
    return new Error('An error occurred, please try again');
  }
}

export async function setSubscription(articleId, subscriptionType) {
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

    if (typeof subscribed !== 'boolean') {
      addSnackbarItem({
        message: 'An error occurred, please try again',
        addCloseButton: true,
      });
      return;
    }

    let message = 'You have been unsubscribed from comments for this post';

    if (subscribed) {
      message = `You have been subscribed to ${subscriptionType.replace(
        /_/g,
        ' ',
      )}`;
    }

    addSnackbarItem({ message, addCloseButton: true });
  } catch (error) {
    addSnackbarItem({
      message: 'An error occurred, please try again',
      addCloseButton: true,
    });
  }
}
