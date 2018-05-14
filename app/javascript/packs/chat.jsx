import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import Chat from '../chat/chat';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

document.ready.then(
  getUserDataAndCsrfToken().then(currentUser => {
    if (document.getElementById('chat')) {
      const { chatChannels, pusherKey, chatOptions } = document.getElementById(
        'chat',
      ).dataset;
      window.currentUser = currentUser;
      window.csrfToken = document.querySelector(
        "meta[name='csrf-token']",
      ).content;
      const root = render(
        <Chat
          pusherKey={pusherKey}
          chatChannels={chatChannels}
          chatOptions={chatOptions}
        />,
        document.getElementById('chat'),
      );
      window.InstantClick.on('change', () => {
        render('', document.body, root);
      });
    }
  }),
);
