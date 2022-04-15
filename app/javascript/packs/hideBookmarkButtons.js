/* global userData */

const { id: currentUserId } = userData();

document.querySelectorAll('.bookmark-button').forEach((button) => {
  const { articleAuthorId } = button.dataset;
  if (currentUserId && articleAuthorId == currentUserId) {
    button.classList.add('hidden');
  }
});
