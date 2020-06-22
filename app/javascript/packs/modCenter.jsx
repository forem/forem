import { h, render } from 'preact';
import { ModerationArticles } from '../modCenter/moderationArticles';

let elementLoaded = false;

function loadElement() {
  const root = document.getElementById('mod-index-list');
  const isMobileDevice = typeof window.orientation !== 'undefined';

  if (root) {
    render(<ModerationArticles />, root);
  }

  if (isMobileDevice) {
    // eslint-disable-next-line no-alert
    alert('The Mod Center is best viewed on desktop');
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
  elementLoaded = true;
}
