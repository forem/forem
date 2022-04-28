import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

getUserDataAndCsrfToken().then(({ currentUser }) => {
  const currentUserId = currentUser && currentUser.id;

  document.querySelectorAll('.bookmark-button').forEach((button) => {
    const { articleAuthorId } = button.dataset;
    if (currentUserId && articleAuthorId == currentUserId) {
      button.classList.add('hidden');
    }
  });
});
