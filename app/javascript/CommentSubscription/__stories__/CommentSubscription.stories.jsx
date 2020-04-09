import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { CommentSubscription } from '../CommentSubscription';

export default {
  title: 'App Components/Comment Subscription',
};

export const Default = () => (
  <CommentSubscription
    onSubscribe={action('subscribed')}
    onUnsubscribe={action('unsubscribed')}
  />
);
