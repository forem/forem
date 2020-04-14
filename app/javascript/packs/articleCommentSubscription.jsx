import { h, render } from 'preact';
import { CommentSubscription } from '../CommentSubscription/CommentSubscription';

const root = document.getElementById('comment-subscription');

const onSubscribe = () => {};
const onUnsubscribe = () => {};

render(
  <CommentSubscription
    positionType="static"
    onSubscribe={(_event) => onSubscribe()}
    onUnsubscribe={(_event) => onUnsubscribe()}
  />,
  root,
  root.firstElementChild,
);
