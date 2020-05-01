import { request } from '../utilities/http/request';

/**
 * Gets the comment subscription status for a given article.
 *
 * @param {number} articleId
 *
 * @returns {string} The subscription status.
 */
export async function getCommentSubscriptionStatus(articleId) {
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

/**
 * Set's the subscription status for a given article.
 *
 * @param {number} articleId
 * @param {string} subscriptionType
 *
 * @returns {string} A friendly message in regards to subscription status.
 */
export async function setCommentSubscriptionStatus(
  articleId,
  subscriptionType,
) {
  let message;

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
      message = 'An error occurred, please try again';

      return message;
    }

    message = 'You have been unsubscribed from comments for this post';

    if (subscribed) {
      message = `You have been subscribed to ${subscriptionType.replace(
        /_/g,
        ' ',
      )}`;
    }
  } catch (error) {
    message = 'An error occurred, please try again';
  }

  return message;
}
