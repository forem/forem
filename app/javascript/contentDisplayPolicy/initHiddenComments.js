/* eslint-disable no-alert */
export function initHiddenComments() {
  function hide(commentId) {
    const confirmMsg = `
Are you sure you want to hide this comment? It will become hidden in your post, but will still be visible via the comment's permalink.

All child comments in this thread will also be hidden.

For further actions, you may consider blocking this person and/or reporting abuse.
    `;
    const confirmHide = window.confirm(confirmMsg);
    if (confirmHide) {
      fetch(`/comments/${commentId}/hide`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': window.csrfToken,
        },
      })
        .then((response) => response.json())
        .then((response) => {
          if (response.hidden === 'true') {
            /* eslint-disable-next-line no-restricted-globals */
            location.reload();
          }
        });
    }
  }

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
    const form = document.getElementById("hide-comments-modal__form");
    form.action = `/comments/${commentId}/hide`;
    // const comment_id_input = form.getElementsByClassName("hide_comment_id")[0];
    // comment_id_input.value = commentId;
    window.Forem.showModal({
      title: 'Are you sure you want to hide this comment?',
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
        // hide(commentId);
      });
    } else if (hideType === 'unhide') {
      link.addEventListener('click', () => {
        unhide(commentId);
      });
    }
  });
}
/* eslint-enable no-alert */
