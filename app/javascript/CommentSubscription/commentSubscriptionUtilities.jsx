import { request } from '../utilities/http/request';
import { i18next } from '@utilities/locale';

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
    return new Error(i18next.t('errors.subscription'));
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
      message = i18next.t('errors.subscription');

      return message;
    }

    message = i18next.t('comments.subscription.unsubscribed');

    if (subscribed) {
      message = i18next.t('comments.subscription.subscribed', {
        type: i18next.t(`comments.subscription.type.${subscriptionType}`),
      });
    }
  } catch (error) {
    message = i18next.t('errors.subscription');
  }

  return message;
}
