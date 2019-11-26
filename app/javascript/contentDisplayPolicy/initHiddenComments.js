/* eslint-disable no-alert */
export default function initHiddenComments() {
  function hide(commentId) {
    const confirmMsg = `
    Are you sure you want to hide this comment? This will hide the comment in your post, but will still be visible in the comment's permalink.

    You can also consider blocking the person or reporting abuse.
    `;
    const confirmHide = window.confirm(confirmMsg)
    if(confirmHide) {
      fetch(`/comments/${commentId}/hide`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': window.csrfToken,
        },
      })
        .then(response => response.json())
        .then(response => {
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
      .then(response => response.json())
      .then(response => {
        if (response.hidden === 'false') {
          /* eslint-disable-next-line no-restricted-globals */
          location.reload();
        }
      });
  }

  const hideButtons = Array.from(
    document.getElementsByClassName('hide-comment')
  )
  
  hideButtons.forEach(butt => {
    const { hideType, commentId } = butt.dataset
    if (hideType === 'hide') {
      butt.addEventListener('click', () => {
        hide(commentId)
      })
    } else if (hideType === 'unhide') {
      butt.addEventListener('click', () => {
        unhide(commentId);
      });
    }
  })
}
/* eslint-enable no-alert */