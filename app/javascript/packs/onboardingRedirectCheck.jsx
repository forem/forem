import { getUserDataAndCsrfToken } from '../chat/util';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function redirectableLocation() {
  return (
    window.location.pathname !== '/onboarding' &&
    window.location.pathname !== '/signout_confirm'
  );
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser }) => {
      if (redirectableLocation() && !currentUser.saw_onboarding) {
        window.location = `${window.location.origin}/onboarding`;
      }
    })
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    }),
);
