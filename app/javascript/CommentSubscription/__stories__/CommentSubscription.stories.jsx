import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { withKnobs, text, boolean } from '@storybook/addon-knobs/react';
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

export const Default = () => (
  <CommentSubscription
    subscribed={boolean('subscribed', false)}
    {...commonProps}
  />
);

Default.story = {
  name: 'unsubscribed (default)',
};

export const Subscribed = () => (
  <CommentSubscription
    subscribed={boolean('subscribed', true)}
    {...commonProps}
  />
);

Subscribed.story = {
  name: 'subscribed',
};

export const SubscribedToNonDefaultSubscriptionType = () => (
  <CommentSubscription
    subscribed={boolean('subscribed', true)}
    subscriptionType={text(
      'subscriptionType',
      COMMENT_SUBSCRIPTION_TYPE.AUTHOR,
    )}
    {...commonProps}
  />
);

SubscribedToNonDefaultSubscriptionType.story = {
  name: 'subscribed to non-default subscription type',
};
