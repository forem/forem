/* global activateRunkitTags */

function getAndShowPreview(preview, editor) {
  function successCb(body) {
    preview.innerHTML = body.processed_html; // eslint-disable-line no-param-reassign
    activateRunkitTags();
  }

  const payload = JSON.stringify({
    comment: {
      body_markdown: editor.value,
    },
  });
  getCsrfToken()
    .then(sendFetch('comment-preview', payload))
    .then((response) => {
      return response.json();
    })
    .then(successCb)
    .catch((err) => {
      console.log('error!'); // eslint-disable-line
      console.log(err); // eslint-disable-line no-console
    });
}

function handleCommentPreview(event) {
  event.preventDefault();
  const { form } = event.target;
  const editor = form.querySelector('.comment-textarea');
  const preview = form.querySelector('.comment-form__preview');
  const trigger = form.querySelector('.preview-toggle');

  if (editor.value !== '') {
    if (form.classList.contains('preview-open')) {
      form.classList.toggle('preview-open');
      trigger.innerHTML = 'Preview';
    } else {
      getAndShowPreview(preview, editor);
      const editorHeight = editor.offsetHeight + 43; // not ideal but prevents jumping screen
      preview.style.minHeight = `${editorHeight}px`;
      trigger.innerHTML = 'Continue editing';
      form.classList.toggle('preview-open');
    }
  }
}

function initializeCommentPreview() {
  const previewButton = document.querySelector('.preview-toggle');

  if (!previewButton) {
    return;
  }

  previewButton.addEventListener('click', handleCommentPreview);
}
