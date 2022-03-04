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

  function showHideCommentsModal(commentId, commentUrl) {
    const form = document.getElementById('hide-comments-modal__form');
    form.action = `/comments/${commentId}/hide`;

    const report_link = document.getElementById(
      'hide-comments-modal__report-link',
    );
    report_link.href = `/report-abuse?url=${commentUrl}`;

    const comment_permalink = document.getElementById(
      'hide-comments-modal__comment-permalink',
    );
    comment_permalink.href = commentUrl;

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

  const hideButtons = Array.from(
    document.getElementsByClassName('hide-comment'),
  );

  hideButtons.forEach((butt) => {
    const { commentId, commentUrl } = butt.dataset;
    butt.addEventListener('click', (e) => {
      e.preventDefault();
      showHideCommentsModal(commentId, commentUrl);
    });
  });

  const unhideLinks = Array.from(
    document.getElementsByClassName('unhide-comment'),
  );

  unhideLinks.forEach((link) => {
    const { commentId } = link.dataset;
    link.addEventListener('click', (e) => {
      e.preventDefault();
      unhide(commentId);
    });
  });

  const handleHideCommentsFormSubmit = (e) => {
    e.preventDefault();
    e.stopPropagation();
    const { target: form } = e;
    const hide_children_check = form.getElementsByClassName('hide_children')[0];
    const url = `${form.action}${
      hide_children_check.checked ? '?hide_children=1' : ''
    }`;

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
