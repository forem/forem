import { h, render } from 'preact';

import { ReadingList } from '../readingList/readingList';
import { Snackbar } from '../Snackbar/Snackbar';

function loadElement() {
  const root = document.getElementById('reading-list');
  if (root) {
    render(<Snackbar lifespan="1" />, document.getElementById('snack-zone'));
    render(
      <ReadingList availableTags={[]} statusView={root.dataset.view} />,
      root,
    );
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
