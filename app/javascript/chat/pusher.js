import Pusher from 'pusher-js';

export default function setupPusher(key, callback) {
  const pusher = new Pusher(key, {
    cluster: 'us2',
    encrypted: true,
  });

  const channel = pusher.subscribe('1');
  channel.bind('message-created', callback);
}
