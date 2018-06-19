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
      const { chatChannels, pusherKey, chatOptions, algoliaKey, algoliaId, algoliaIndex, githubToken } = document.getElementById(
        'chat',
      ).dataset;
      window.currentUser = currentUser;
      window.csrfToken = document.querySelector(
        "meta[name='csrf-token']",
      ).content;
      const renderTarget = document.getElementById('chat');
      const placeholder = document.getElementById('chat_placeholder')
      const root = render(
        <Chat
          pusherKey={pusherKey}
          chatChannels={chatChannels}
          chatOptions={chatOptions}
          algoliaId={algoliaId}
          algoliaKey={algoliaKey}
          algoliaIndex={algoliaIndex}
          githubToken={githubToken}
        />,
        renderTarget, renderTarget.firstChild
      );
      renderTarget.removeChild(placeholder);
      window.InstantClick.on('change', () => {
        render('', document.body, root);
      });
    }
  }),
);
