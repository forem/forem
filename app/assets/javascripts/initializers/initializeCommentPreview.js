/* global activateRunkitTags */

function getAndShowPreview(preview, editor) {
  function attachTwitterTimelineScript() {
    const script = document.createElement('script');
    script.src = 'https://platform.twitter.com/widgets.js';
    script.async = true;
    document.body.appendChild(script);
    return () => {
      document.body.removeChild(script);
    };
  }

  function successCb(body) {
    preview.innerHTML = body.processed_html; // eslint-disable-line no-param-reassign
    if (body.processed_html.includes('twitter-timeline')) {
      attachTwitterTimelineScript();
    }
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
  const editor = form.getElementsByClassName('comment-textarea')[0];
  const preview = form.getElementsByClassName('comment-form__preview')[0];
  const trigger = form.getElementsByClassName('preview-toggle')[0];

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
  const previewButton = document.getElementsByClassName('preview-toggle')[0];

  if (!previewButton) {
    return;
  }

  previewButton.addEventListener('click', handleCommentPreview);
}
