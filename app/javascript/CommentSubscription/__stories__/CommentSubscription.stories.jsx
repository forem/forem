import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { withKnobs, text } from '@storybook/addon-knobs/react';
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
    {...commonProps}
    subscriptionType={text('subscriptionType')}
  />
);

Default.story = {
  name: 'unsubscribed with no subscription type (default)',
};

export const Unsubscribed = () => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={text(
      'subscriptionType',
      COMMENT_SUBSCRIPTION_TYPE.NOT_SUBSCRIBED,
    )}
  />
);

Unsubscribed.story = {
  name: 'unsubscribed',
};

export const Subscribed = () => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={text(
      'subscriptionType',
      COMMENT_SUBSCRIPTION_TYPE.AUTHOR,
    )}
  />
);

Subscribed.story = {
  name: 'subscribed',
};
