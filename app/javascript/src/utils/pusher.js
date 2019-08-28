// import Pusher from 'pusher-js';

export default function setupPusher(key, callbackObjects) {
  return import('pusher-js').then(_ => {
    const {
      pusher = new Pusher(key, {
        authEndpoint: '/pusher/auth',
        auth: {
          headers: {
            'X-CSRF-Token': window.csrfToken,
          },
        },
        cluster: 'us2',
        encrypted: true,
      }),
    } = window;

    window.pusher = pusher;

    const channel = pusher.subscribe(callbackObjects.channelId.toString());
    channel.bind('message-created', callbackObjects.messageCreated);
    channel.bind('channel-cleared', callbackObjects.channelCleared);
    channel.bind('user-banned', callbackObjects.redactUserMessages);
    channel.bind('client-livecode', callbackObjects.liveCoding);
    channel.bind(
      'client-initiatevideocall',
      callbackObjects.videoCallInitiated,
    );
    channel.bind('client-endvideocall', callbackObjects.videoCallEnded);

    // channel.bind('pusher:subscription_succeeded', callbackObjects.channelSubscribed);
    channel.bind('pusher:subscription_error', callbackObjects.channelError);
    return channel;
  });
}
