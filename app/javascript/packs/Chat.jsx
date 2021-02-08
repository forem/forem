import { h, render } from 'preact';
import { Chat } from '../chat/chat';
import { Snackbar } from '../Snackbar/Snackbar';

function loadElement() {
  const root = document.getElementById('chat');

  if (root) {
    render(<Snackbar lifespan="3" />, document.getElementById('snack-zone'));
    render(<Chat {...root.dataset} />, root);

    const placeholder = document.getElementById('chat_placeholder');

    if (placeholder) {
      root.removeChild(placeholder);
    }
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
