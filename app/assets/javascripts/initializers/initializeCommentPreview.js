function initializeCommentPreview() {
  if (document.getElementById('preview-button')) {
    document.getElementById('preview-button').onclick = handleCommentPreview;
  }
}

function handleCommentPreview(e) {
  e.preventDefault();
  var form = e.target.parentElement.parentElement;
  var textArea = form.querySelector('textarea');
  if (textArea.value !== '') {
    var previewDiv = form.querySelector('.comment-preview-div');
    var previewButton = form.querySelector('.comment-action-preview');
    if (previewButton.innerHTML.indexOf('PREVIEW') > -1) {
      textArea.classList.toggle('preview-loading');
      getAndShowPreview(previewDiv, textArea);
      previewButton.innerHTML = 'MARKDOWN';
    } else {
      previewDiv.classList.toggle('preview-toggle');
      textArea.classList.toggle('preview-toggle');
      previewButton.innerHTML = 'PREVIEW';
    }
  }
}

function getAndShowPreview(previewDiv, textArea) {
  var commentMarkdown = textArea.value;
  var payload = JSON.stringify({
    comment: {
      body_markdown: commentMarkdown,
    },
  });
  getCsrfToken()
    .then(sendFetch('comment-preview', payload))
    .then(function(response) {
      return response.json();
    })
    .then(successCb)
    .catch(function(err) {
      console.log('error!');
      console.log(err);
    });

  function successCb(body) {
    previewDiv.classList.toggle('preview-toggle');
    textArea.classList.toggle('preview-loading');
    textArea.classList.toggle('preview-toggle');
    previewDiv.innerHTML = body.processed_html;
  }
}
