import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

// If localStorage.getItem('shouldRedirectToOnboarding') is not set, i.e. null, that means we should redirect.
function redirectableLocation() {
  return (
    window.location.pathname !== '/onboarding' &&
    window.location.pathname !== '/signout_confirm' &&
    window.location.pathname !== '/privacy' &&
    window.location.pathname !== '/admin/creator_settings/new'
  );
}

function onboardingSkippable(currentUser) {
  return (
    currentUser.saw_onboarding &&
    currentUser.checked_code_of_conduct &&
    currentUser.checked_terms_and_conditions
  );
}

function onboardCreator(currentUser) {
  return (
    document.body.dataset.creator === 'true' &&
    document.body.dataset.creatorOnboarding === 'true' &&
    !currentUser.saw_onboarding
  );
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;

      if (redirectableLocation() && onboardCreator(currentUser)) {
        window.location = `${window.location.origin}/admin/creator_settings/new?referrer=${window.location}`;
      } else if (redirectableLocation() && !onboardingSkippable(currentUser)) {
        window.location = `${window.location.origin}/onboarding?referrer=${window.location}`;
      }
    })
    .catch((error) => {
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
        onboardCreator(currentUser)
      ) {
        window.location = `${window.location.origin}/admin/creator_settings/new?referrer=${window.location}`;
      } else if (
        redirectableLocation() &&
        localStorage.getItem('shouldRedirectToOnboarding') === null &&
        !onboardingSkippable(currentUser)
      ) {
        window.location = `${window.location.origin}/onboarding?referrer=${window.location}`;
      }
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    });
});
