import { locale } from '@utilities/locale';
import { initializeMermaidDiagrams } from '@utilities/mermaidDiagrams';

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
    initializeMermaidDiagrams(preview);
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
      trigger.innerHTML = locale('core.comments_preview');
    } else {
      getAndShowPreview(preview, editor);
      const editorHeight = editor.offsetHeight + 43; // not ideal but prevents jumping screen
      preview.style.minHeight = `${editorHeight}px`;
      trigger.innerHTML = locale('core.comments_continue_editing');
      form.classList.toggle('preview-open');
    }
  }
}

export function initializeCommentPreview() {
  // Always expose the handler so server-rendered inline `onclick` attributes
  // (e.g. comment notifications loaded later via pagination) can call it.
  window.handleCommentPreview = handleCommentPreview;

  const previewButton = document.getElementsByClassName('preview-toggle')[0];

  if (!previewButton) {
    return;
  }

  // Buttons with an inline onclick already invoke the handler; attaching a
  // listener too would fire it twice per click and toggle the preview back off.
  if (!previewButton.getAttribute('onclick')) {
    previewButton.addEventListener('click', handleCommentPreview);
  }
}
