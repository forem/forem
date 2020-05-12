import { getUserDataAndCsrfToken } from '../chat/util';
import getUnopenedChannels from '../src/utils/getUnopenedChannels';

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
    window.location.pathname !== '/signout_confirm' &&
    window.location.pathname !== '/privacy'
  );
}

function onboardingSkippable(currentUser) {
  return (
    currentUser.saw_onboarding &&
    currentUser.checked_code_of_conduct &&
    currentUser.checked_terms_and_conditions
  );
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;
      getUnopenedChannels();

      if (redirectableLocation() && !onboardingSkippable(currentUser)) {
        window.location = `${window.location.origin}/onboarding?referrer=${window.location}`;
      }
    })
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    }),
);

window.InstantClick.on('change', () => {
  getUserDataAndCsrfToken()
    .then(({ currentUser }) => {
      if (
        redirectableLocation() &&
        localStorage.getItem('shouldRedirectToOnboarding') === null &&
        !onboardingSkippable(currentUser)
      ) {
        window.location = `${window.location.origin}/onboarding?referrer=${window.location}`;
      }
    })
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    });
});
