import { h } from 'preact';
import { ReadingList } from '../readingList/readingList';
import { render } from '@utilities/preact/render';

function loadElement() {
  const root = document.getElementById('reading-list');
  if (root) {
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
