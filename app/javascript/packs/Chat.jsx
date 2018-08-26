import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import Chat from '../chat/chat';

function initializeChat(loadChat) {
  getUserDataAndCsrfToken()
    .then(loadChat)
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Unable to load chat', error);
    });
}

function renderChat(root) {
  render(<Chat {...root.dataset} />, root, root.firstChild);
}

const loadChat = ({ currentUser, csrfToken }) => {
  const root = document.getElementById('chat');

  if (!root) {
    return;
  }

  window.currentUser = currentUser;
  window.csrfToken = csrfToken;

  const placeholder = document.getElementById('chat_placeholder');

  renderChat(root);

  if (placeholder) {
    root.removeChild(placeholder);
  }

  window.InstantClick.on('change', () => {
    if (window.location.href.indexOf('/connect') === -1) {
      return;
    }

    renderChat(root);
  });
};

initializeChat(loadChat);

window.InstantClick.on('change', () => {
  initializeChat(loadChat);
});
