import { h, render } from 'preact';
import { ModerationArticles } from '../moderationArticles/moderationArticles';

function loadElement() {
  const root = document.getElementById('mod-index-list');
  if (root) {
    render(<ModerationArticles />, root, root.secondElementChild);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
