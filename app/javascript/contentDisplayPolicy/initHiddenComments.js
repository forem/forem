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

  const hideLinks = Array.from(document.getElementsByClassName('hide-comment'));

  hideLinks.forEach((link) => {
    const { hideType, commentId } = link.dataset;

    if (hideType === 'hide') {
      link.addEventListener('click', () => {
        hide(commentId);
      });
    } else if (hideType === 'unhide') {
      link.addEventListener('click', () => {
        unhide(commentId);
      });
    }
  });
}
/* eslint-enable no-alert */
