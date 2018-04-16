import Pusher from 'pusher-js';

export default function setupPusher(key, callbackObjects) {
  const pusher = new Pusher(key, {
    cluster: 'us2',
    encrypted: true,
  });

  const channel = pusher.subscribe('1');
  channel.bind('message-created', callbackObjects.messageCreated);
  channel.bind('channel-cleared', callbackObjects.channelCleared);
  channel.bind('user-banned', callbackObjects.redactUserMessages);
}
