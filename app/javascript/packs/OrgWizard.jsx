import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function renderWizard() {
  const container = document.getElementById('org-wizard-container');
  if (!container) return;

  const config = {
    organization: JSON.parse(container.dataset.organization),
    crawlUrl: container.dataset.crawlUrl,
    generateUrl: container.dataset.generateUrl,
    iterateUrl: container.dataset.iterateUrl,
    previewUrl: container.dataset.previewUrl,
    saveUrl: container.dataset.saveUrl,
    settingsUrl: container.dataset.settingsUrl,
  };

  import('../orgWizard/OrgWizard')
    .then(({ OrgWizard }) => {
      render(<OrgWizard {...config} />, container);
    })
    .catch((error) => {
      console.error('Unable to load OrgWizard', error);
    });
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;
      renderWizard();
    })
    .catch((error) => {
      console.error('Error getting user and CSRF Token', error);
    }),
);
