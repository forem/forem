import { h, render } from 'preact';
import { ModerationArticles } from '../modCenter/moderationArticles';
import { initializeModCenterFunctions } from '../modCenter/modCenter';

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
initializeModCenterFunctions();
