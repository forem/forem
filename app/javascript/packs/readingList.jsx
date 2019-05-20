import { h, render } from 'preact';
import { ReadingList } from '../readingList/readingList';

function loadElement() {
  const root = document.getElementById('reading-list');
  if (root) {
    render(<ReadingList />, root, root.firstElementChild);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
