import { h, render } from 'preact';
import { CommentSubscription } from '../CommentSubscription/CommentSubscription';

const root = document.getElementById('comment-subscription');

render(
  <CommentSubscription
    onSubscribe={(_event) => console.log('subscribed')}
    onUnsubscribe={(_event) => console.log('unsubscribed')}
  />,
  root,
  root.firstElementChild,
);
