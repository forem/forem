import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import { History } from '../history/history';

function loadComponent() {
  getUserDataAndCsrfToken().then(({ currentUser }) => {
    const root = document.getElementById('history');
    if (root) {
      render(
        <History availableTags={currentUser.followed_tag_names} />,
        root,
        root.firstElementChild,
      );
    }
  });
}

window.InstantClick.on('change', () => {
  loadComponent();
});

loadComponent();
