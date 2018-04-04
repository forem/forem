import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import Chat from '../chat/chat';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') { return resolve(); }
  document.addEventListener('DOMContentLoaded', () => resolve());
});

document.ready
  .then(getUserDataAndCsrfToken()
    .then((currentUser) => {
      if (document.getElementById('chat')) {
        const { pusherKey } = document.getElementById('chat').dataset;
        window.currentUser = currentUser;
        window.csrfToken = document.querySelector("meta[name='csrf-token']").content;
        render(
          <Chat pusherKey={pusherKey} />,
          document.getElementById('chat'),
        );
      }
    }));
