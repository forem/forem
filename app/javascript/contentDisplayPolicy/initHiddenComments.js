/* eslint-disable no-alert */
export function initHiddenComments() {
  function unhide(commentId) {
    fetch(`/comments/${commentId}/unhide`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': window.csrfToken,
      },
    })
      .then((response) => response.json())
      .then((response) => {
        if (response.hidden === 'false') {
          /* eslint-disable-next-line no-restricted-globals */
          location.reload();
        }
      });
  }

  function showHideCommentsModal(commentId) {
    const form = document.getElementById('hide-comments-modal__form');
    form.action = `/comments/${commentId}/hide`;
    window.Forem.showModal({
      title: 'Confirm hiding the comment',
      contentSelector: '#hide-comments-modal',
      overlay: true,
    });
  }

  const hideLinks = Array.from(document.getElementsByClassName('hide-comment'));

  hideLinks.forEach((link) => {
    const { hideType, commentId } = link.dataset;
    if (hideType === 'hide') {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        showHideCommentsModal(commentId);
      });
    } else if (hideType === 'unhide') {
      link.addEventListener('click', () => {
        unhide(commentId);
      });
    }
  });
}
/* eslint-enable no-alert */
