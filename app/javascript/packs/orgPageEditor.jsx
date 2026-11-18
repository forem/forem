import { h, render } from 'preact';
import { OrgPageEditor } from '../orgPageEditor/OrgPageEditor';
import { Snackbar } from '../Snackbar';
import { getCsrfToken, getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function resolveEditorSession() {
  if (document.body.classList.contains('admin') && !document.body.dataset.user) {
    return Promise.resolve({ currentUser: null, csrfToken: getCsrfToken() });
  }

  return getUserDataAndCsrfToken().catch(() => ({
    currentUser: null,
    csrfToken: getCsrfToken(),
  }));
}

function loadEditor() {
  const snackZone = document.getElementById('snack-zone');
  if (snackZone) {
    render(<Snackbar lifespan={3} />, snackZone);
  }

  const container = document.getElementById('org-page-editor-root');
  if (!container) return;

  resolveEditorSession().then(({ currentUser, csrfToken }) => {
    window.currentUser = currentUser;
    window.csrfToken = csrfToken;

    const { defaultValue, textareaName, previewUrl, placeholder } = container.dataset;
    const fallbackTextarea = container.querySelector('textarea');
    const initialValue = fallbackTextarea ? fallbackTextarea.value : defaultValue;

    // Remove the server-rendered fallback textarea before mounting Preact
    container.innerHTML = '';

    render(
      <OrgPageEditor
        defaultValue={initialValue || ''}
        textAreaName={textareaName}
        previewUrl={previewUrl}
        placeholder={placeholder}
      />,
      container,
    );
  });
}

document.ready.then(() => {
  loadEditor();
  if (window.InstantClick && typeof window.InstantClick.on === 'function') {
    window.InstantClick.on('change', () => {
      if (document.getElementById('org-page-editor-root')) {
        loadEditor();
      }
    });
  }
});
