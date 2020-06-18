import { h, render } from 'preact';
import { ModerationArticles } from '../modCenter/moderationArticles';
import { initializeModCenterFunctions } from '../modCenter/modCenter';

let elementLoaded = false;

function loadElement() {
  const root = document.getElementById('mod-index-list');
  if (root) {
    render(<ModerationArticles />, root);
  }
}

window.InstantClick.on('change', () => {
  if (!elementLoaded) {
    loadElement();
    elementLoaded = true;
  }
});

if (!elementLoaded) {
  loadElement();
  initializeModCenterFunctions();
  elementLoaded = true;
}
