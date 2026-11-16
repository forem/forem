import { locale } from './locale';
import {
  initializeSandboxedEmbeds,
  prepareEmbedPreviewReload,
} from './pageEmbedWrapper';

function tPreview(key, fallback) {
  const translated = locale(`core.embed_sandbox.${key}`);
  return translated.startsWith('[missing ') ? fallback : translated;
}

async function getCsrfTokenValue() {
  const metaToken = document
    .querySelector('meta[name="csrf-token"]')
    ?.getAttribute('content');
  if (metaToken) return metaToken;

  if (typeof globalThis.getCsrfToken === 'function') {
    const token = await globalThis.getCsrfToken();
    if (typeof token === 'string' && token) return token;
  }
  return '';
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
        const csrfToken = await getCsrfTokenValue();
        if (currentReq !== requestCounter) return;

        const response = await fetch(previewUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            'X-CSRF-Token': csrfToken,
          },
          credentials: 'same-origin',
          body: JSON.stringify({ body_html: textarea.value || '' }),
        });

        if (currentReq !== requestCounter) return;

        let payload = null;
        try {
          payload = await response.json();
        } catch (_parseErr) {
          payload = null;
        }
        if (currentReq !== requestCounter) return;

        if (!response.ok || typeof payload?.wrapped_html !== 'string') {
          const failure = new Error('Unable to render preview');
          if (typeof payload?.error === 'string' && payload.error) {
            failure.serverMessage = payload.error;
          }
          throw failure;
        }

        initializeSandboxedEmbeds(previewPane);
        prepareEmbedPreviewReload(previewPane, () => {
          loadPreview();
        });
        frame.srcdoc = payload.wrapped_html;
      } catch (err) {
        if (currentReq !== requestCounter) return;
        frame.srcdoc = '';
        if (errorNotice) {
          errorNotice.textContent =
            (err && err.serverMessage) ||
            errorNotice.dataset.defaultError ||
            tPreview(
              'preview_error',
              'Unable to render sandboxed preview right now.',
            );
          errorNotice.classList.remove('hidden');
        }
      }
    }

    editBtn.addEventListener('click', showEdit);
    previewBtn.addEventListener('click', loadPreview);
  });
}
