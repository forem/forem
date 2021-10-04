import i18next from 'i18next';

/* eslint-disable no-alert */
export function initHiddenComments() {
  function hide(commentId) {
    const confirmMsg = i18next.t('comments.hide');
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
