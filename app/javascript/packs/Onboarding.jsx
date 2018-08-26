import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import getUnopenedChannels from '../src/utils/getUnopenedChannels';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function shouldShowOnboarding() {
  const { user } = document.body.dataset;

  return (
    document.head.getElementsByTagName('meta')[2].content === 'true' &&
    user &&
    JSON.parse(user).saw_onboarding === false
  );
}

function renderPage() {
  if (shouldShowOnboarding()) {
    import('../src/Onboarding').then(({ default: Onboarding }) =>
      render(<Onboarding />, document.getElementById('top-bar')),
    );
  }
}

document.ready.then(
  getUserDataAndCsrfToken().then(({ currentUser, csrfToken }) => {
    window.currentUser = currentUser;
    window.csrfToken = csrfToken;

    renderPage();
    getUnopenedChannels();
  }),
);
