import {
  initializeSandboxedEmbeds,
  prepareEmbedPreviewReload,
} from './pageEmbedWrapper';

function getCsrfTokenValue() {
  if (typeof globalThis.getCsrfToken === 'function') {
    const token = globalThis.getCsrfToken();
    if (token) return token;
  }
  return (
    document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content') || ''
  );
}

export function initializeEmbedEditorPreviews(root = document) {
  if (!root || typeof root.querySelectorAll !== 'function') return;

  const editors = root.querySelectorAll('[data-embed-editor="true"]');
  editors.forEach((editor) => {
    if (editor.dataset.initialized === 'true') return;
    editor.dataset.initialized = 'true';

    const editBtn = editor.querySelector('[data-embed-tab="edit"]');
    const previewBtn = editor.querySelector('[data-embed-tab="preview"]');
    const editPane = editor.querySelector('[data-embed-pane="edit"]');
    const previewPane = editor.querySelector('[data-embed-pane="preview"]');
    const textarea = editor.querySelector('[data-embed-input="body_html"]');
    const frame = editor.querySelector('[data-embed-preview-frame="true"]');
    const errorNotice = editor.querySelector('[data-embed-preview-error="true"]');
    const previewUrl = editor.dataset.previewUrl;

    if (
      !editBtn ||
      !previewBtn ||
      !editPane ||
      !previewPane ||
      !textarea ||
      !frame
    ) {
      return;
    }

    let requestCounter = 0;

    function showEdit() {
      previewPane.classList.add('hidden');
      editPane.classList.remove('hidden');
      editBtn.className = 'crayons-btn crayons-btn--secondary crayons-btn--s';
      previewBtn.className = 'crayons-btn crayons-btn--ghost crayons-btn--s';
      editBtn.setAttribute('aria-selected', 'true');
      previewBtn.setAttribute('aria-selected', 'false');
    }

    async function loadPreview() {
      const currentReq = ++requestCounter;
      editPane.classList.add('hidden');
      previewPane.classList.remove('hidden');
      previewBtn.className = 'crayons-btn crayons-btn--secondary crayons-btn--s';
      editBtn.className = 'crayons-btn crayons-btn--ghost crayons-btn--s';
      previewBtn.setAttribute('aria-selected', 'true');
      editBtn.setAttribute('aria-selected', 'false');

      if (errorNotice) {
        errorNotice.classList.add('hidden');
        errorNotice.textContent = '';
      }

      if (!previewUrl) return;

      try {
        const response = await fetch(previewUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            'X-CSRF-Token': getCsrfTokenValue(),
          },
          credentials: 'same-origin',
          body: JSON.stringify({ body_html: textarea.value || '' }),
        });

        if (currentReq !== requestCounter) return;
        const payload = await response.json();
        if (!response.ok || typeof payload.wrapped_html !== 'string') {
          throw new Error(payload?.error || 'Unable to render preview');
        }

        initializeSandboxedEmbeds(previewPane);
        prepareEmbedPreviewReload(previewPane, () => {
          loadPreview();
        });
        frame.srcdoc = payload.wrapped_html;
      } catch (_err) {
        if (currentReq !== requestCounter) return;
        frame.srcdoc = '';
        if (errorNotice) {
          errorNotice.textContent =
            errorNotice.dataset.defaultError ||
            'Unable to render sandboxed preview right now.';
          errorNotice.classList.remove('hidden');
        }
      }
    }

    editBtn.addEventListener('click', showEdit);
    previewBtn.addEventListener('click', loadPreview);
  });
}
