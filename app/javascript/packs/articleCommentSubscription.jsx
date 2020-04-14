import { h, render } from 'preact';
import {
  CommentSubscription,
  COMMENT_SUBSCRIPTION_TYPE,
} from '../CommentSubscription/CommentSubscription';

const root = document.getElementById('comment-subscription');

const onSubscribe = () => {};
const onUnsubscribe = () => {};
const someSubscriptionType = COMMENT_SUBSCRIPTION_TYPE.TOP;

render(
  <CommentSubscription
    subscriptionType={someSubscriptionType}
    positionType="static"
    onSubscribe={(_event) => onSubscribe()}
    onUnsubscribe={(_event) => onUnsubscribe()}
  />,
  root,
  root.firstElementChild,
);
