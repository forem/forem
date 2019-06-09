function getAndShowPreview(markdownPreviewPane, markdownEditor) {
  function successCb(body) {
    markdownPreviewPane.classList.toggle('preview-toggle');
    markdownEditor.classList.toggle('preview-loading');
    markdownEditor.classList.toggle('preview-toggle');
    markdownPreviewPane.innerHTML = body.processed_html; // eslint-disable-line no-param-reassign
  }

  const payload = JSON.stringify({
    comment: {
      body_markdown: markdownEditor.value,
    },
  });
  getCsrfToken()
    .then(sendFetch('comment-preview', payload))
    .then(response => {
      return response.json();
    })
    .then(successCb)
    .catch(err => {
      console.log('error!'); // eslint-disable-line
      console.log(err); // eslint-disable-line no-console
    });
}

function handleCommentPreview(event) {
  event.preventDefault();
  const { form } = event.target;
  const markdownEditor = form.querySelector('textarea');

  if (markdownEditor.value !== '') {
    const markdownPreviewPane = form.querySelector('.comment-preview-div');
    const previewButton = form.querySelector('.comment-action-preview');

    if (previewButton.innerHTML.indexOf('PREVIEW') > -1) {
      markdownEditor.classList.toggle('preview-loading');
      getAndShowPreview(markdownPreviewPane, markdownEditor);
      previewButton.innerHTML = 'MARKDOWN';
    } else {
      markdownPreviewPane.classList.toggle('preview-toggle');
      markdownEditor.classList.toggle('preview-toggle');
      previewButton.innerHTML = 'PREVIEW';
    }
  }
}

function initializeCommentPreview() {
  const previewButton = document.getElementById('preview-button');

  if (!previewButton) {
    return;
  }

  previewButton.addEventListener('click', handleCommentPreview);
}
