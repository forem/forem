import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import {
  CommentSubscription,
  COMMENT_SUBSCRIPTION_TYPE,
} from '../CommentSubscription';

export default {
  title: 'App Components/Comment Subscription',
  component: CommentSubscription,
  argTypes: {
    subscriptionType: {
      control: { type: 'select' },
      options: Object.values(COMMENT_SUBSCRIPTION_TYPE),
    },
  },
  args: {
    subscriptionType: COMMENT_SUBSCRIPTION_TYPE.NOT_SUBSCRIBED,
  },
};

const commonProps = {
  onSubscribe: action('subscribed'),
  onUnsubscribe: action('unsubscribed'),
};

export const Unsubscribed = (args) => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={args.subscriptionType}
  />
);

Unsubscribed.storyName = 'unsubscribed';
Unsubscribed.args = {
  subscriptionType: COMMENT_SUBSCRIPTION_TYPE.NOT_SUBSCRIBED,
};

export const Subscribed = (args) => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={args.subscriptionType}
  />
);

Subscribed.storyName = 'subscribed';
Subscribed.args = {
  subscriptionType: COMMENT_SUBSCRIPTION_TYPE.ALL,
};

export const SubscribedButNotDefault = (args) => (
  <CommentSubscription
    {...commonProps}
    subscriptionType={args.subscriptionType}
  />
);

SubscribedButNotDefault.storyName =
  'subscribed (with comment type other than the default';
SubscribedButNotDefault.args = {
  subscriptionType: COMMENT_SUBSCRIPTION_TYPE.AUTHOR,
};
