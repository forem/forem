import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import { ReadingList } from '../readingList/readingList';

function loadElement() {
  getUserDataAndCsrfToken().then(({ currentUser }) => {
    const followedTagNames = JSON.parse(currentUser.followed_tags).map(
      (t) => t.name,
    );
    const root = document.getElementById('reading-list');
    if (root) {
      render(
        <ReadingList
          availableTags={followedTagNames}
          statusView={root.dataset.view}
        />,
        root,
      );
    }
  });
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
