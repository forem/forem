import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import { getUnopenedChannels } from '../utilities/connect';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function renderPage() {
  const dataElement = document.getElementById('onboarding-container');
  const communityConfig = {
    communityName: dataElement.dataset.communityName,
    communityLogo: dataElement.dataset.communityLogo,
    communityBackground: dataElement.dataset.communityBackground,
    communityDescription: dataElement.dataset.communityDescription,
  };
  import('../onboarding/Onboarding')
    .then(({ Onboarding }) => {
      render(
        <Onboarding communityConfig={communityConfig} />,
        document.getElementById('onboarding-container'),
      );
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Unable to load onboarding', error);
    });
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;

      getUnopenedChannels();
      renderPage();
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    }),
);
