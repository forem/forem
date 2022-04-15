/* global userData */
const currentUser = userData();
const currentUserId = currentUser && currentUser.id;

document.querySelectorAll('.bookmark-button').forEach((button) => {
  const { articleAuthorId } = button.dataset;
  if (currentUserId && articleAuthorId == currentUserId) {
    button.classList.add('hidden');
  }
});
