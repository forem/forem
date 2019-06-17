import { h, render } from 'preact';
import { History } from '../history/history';

function loadElement() {
  const root = document.getElementById('history');
  if (root) {
    render(<History />, root, root.firstElementChild);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
