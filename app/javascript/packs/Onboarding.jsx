import { h, render } from 'preact';
import Onboarding from '../src/views/Onboarding/Onboarding';
import { getUserDataAndCsrfToken } from '../src/views/Chat/util';
import getUnopenedChannels from '../src/utils/getUnopenedChannels';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function shouldShowOnboarding() {
  return (
    document.head.getElementsByTagName('meta')[2].content === 'true' &&
    document.body.getAttribute('data-user') &&
    document.body.getAttribute('data-user') !== 'undefined' &&
    JSON.parse(document.body.getAttribute('data-user')).saw_onboarding === false
  );
}

function renderPage() {
  if (shouldShowOnboarding()) {
    setTimeout(() => {
      render(<Onboarding />, document.getElementById('top-bar'));
    }, 580);
  }
}

document.ready.then(
  getUserDataAndCsrfToken().then(currentUser => {
    window.currentUser = currentUser;
    window.csrfToken = document.querySelector(
      "meta[name='csrf-token']",
    ).content;
    renderPage();
    getUnopenedChannels();
  }),
);
