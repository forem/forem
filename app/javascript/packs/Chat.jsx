import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../src/views/Chat/util';
import Chat from '../src/views/Chat/chat';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

loadChat(); // Load initially
window.InstantClick.on('change', () => {
  loadChat(); // Load via instantclick nav
});

function loadChat() {
  getUserDataAndCsrfToken().then(currentUser => {
    if (document.getElementById('chat')) {
      const {
        chatChannels,
        pusherKey,
        chatOptions,
        algoliaKey,
        algoliaId,
        algoliaIndex,
        githubToken,
      } = document.getElementById('chat').dataset;
      window.currentUser = currentUser;
      window.csrfToken = document.querySelector(
        "meta[name='csrf-token']",
      ).content;
      const renderTarget = document.getElementById('chat');
      const placeholder = document.getElementById('chat_placeholder');
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
        renderTarget,
        renderTarget.firstChild,
      );
      if (placeholder) {
        renderTarget.removeChild(placeholder);
      }
      window.InstantClick.on('change', () => {
        if (window.location.href.indexOf('/connect') != -1) {
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
            renderTarget,
            renderTarget.firstChild,
          );
        }
      });
    }
  });
}
