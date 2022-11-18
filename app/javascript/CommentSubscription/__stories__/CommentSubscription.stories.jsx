import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { withKnobs, select } from '@storybook/addon-knobs';
import {
  CommentSubscription,
  COMMENT_SUBSCRIPTION_TYPE,
} from '../CommentSubscription';

export default {
  title: 'App Components/Comment Subscription',
  decorators: [withKnobs],
};

const commonProps = {
  onSubscribe: action('subscribed'),
  onUnsubscribe: action('unsubscribed'),
};

export const Unsubscribed = () => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={select(
      'subscriptionType',
      COMMENT_SUBSCRIPTION_TYPE,
      COMMENT_SUBSCRIPTION_TYPE.NOT_SUBSCRIBED,
    )}
  />
);

Unsubscribed.storyName = 'unsubscribed';

export const Subscribed = () => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={select(
      'subscriptionType',
      COMMENT_SUBSCRIPTION_TYPE,
      COMMENT_SUBSCRIPTION_TYPE.ALL,
    )}
  />
);

Subscribed.storyName = 'subscribed';

export const SubscribedButNotDefault = () => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={select(
      'subscriptionType',
      COMMENT_SUBSCRIPTION_TYPE,
      COMMENT_SUBSCRIPTION_TYPE.AUTHOR,
    )}
  />
);

SubscribedButNotDefault.storyName =
  'subscribed (with comment type other than the default';
