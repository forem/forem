import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

Document.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function renderPage(currentUser) {
  // const dataElement = document.getElementById('tags-container');
  import('../tags/Tag')
    .then(({ Tag }) => {
      const tagCards = document.getElementsByClassName('tag-card');

      // deal with if not logged in
      const followedTags = JSON.parse(currentUser.followed_tags);

      Array.from(tagCards).forEach((element) => {
        const followedTag = followedTags.find(
          (tag) => tag.id == element.dataset.tagId,
        );
        // NOTE: this needs to be explicit points and not points
        const following = followedTag?.points >= 0;
        const hidden = followedTag?.points < 0;

        const config = {
          following: following || hidden,
          hidden,
          id: element.dataset.tagId,
          name: element.dataset.tagName,
        };

        render(
          <Tag config={config} />,
          document.getElementById(`tag-buttons-${element.dataset.tagId}`),
        );
      });
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Unable to load tags', error);
    });
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;

      renderPage(currentUser);
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    }),
);
