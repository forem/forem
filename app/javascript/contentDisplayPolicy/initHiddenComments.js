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
    }).then(() => {
      const hideCommentForm = document.querySelector(
        '#window-modal .hide-comments-modal__form',
      );

      hideCommentForm.addEventListener('submit', handleHideCommentsFormSubmit);
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

  const handleHideCommentsFormSubmit = (e) => {
    e.preventDefault();
    e.stopPropagation();
    const { target: form } = e;
    const hide_children_check = form.getElementsByClassName('hide_children')[0];
    let url = form.action;

    if (hide_children_check.checked) {
      url = `${url}?hide_children=1`;
    }

    fetch(url, {
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
  };
}
/* eslint-enable no-alert */
