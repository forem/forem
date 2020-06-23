import { h, render } from 'preact';
import { ModerationArticles } from '../modCenter/moderationArticles';
import { addSnackbarItem, Snackbar } from '../Snackbar';

let elementLoaded = false;

function loadElement() {
  const root = document.getElementById('mod-index-list');
  const isMobileDevice = typeof window.orientation !== 'undefined';
  const snackZone = document.getElementById('snack-zone');

  if (root) {
    render(<ModerationArticles />, root);
  }

  if (snackZone) {
    render(<Snackbar lifespan="0" />, snackZone);
  }

  if (isMobileDevice) {
    addSnackbarItem({
      message: 'The Mod Center is best viewed on desktop.',
      addCloseButton: true,
    });
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
