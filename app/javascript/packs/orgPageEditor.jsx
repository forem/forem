import { h, render } from 'preact';
import { OrgPageEditor } from '../orgPageEditor/OrgPageEditor';
import { Snackbar } from '../Snackbar';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadEditor() {
  const snackZone = document.getElementById('snack-zone');
  if (snackZone) {
    render(<Snackbar lifespan={3} />, snackZone);
  }

  const container = document.getElementById('org-page-editor-root');
  if (!container) return;

  getUserDataAndCsrfToken().then(({ currentUser, csrfToken }) => {
    window.currentUser = currentUser;
    window.csrfToken = csrfToken;

    const { defaultValue, textareaName } = container.dataset;

    // Remove the server-rendered fallback textarea before mounting Preact
    container.innerHTML = '';

    render(
      <OrgPageEditor
        defaultValue={defaultValue || ''}
        textAreaName={textareaName}
      />,
      container,
    );
  });
}

document.ready.then(() => {
  loadEditor();
  window.InstantClick.on('change', () => {
    if (document.getElementById('org-page-editor-root')) {
      loadEditor();
    }
  });
});
