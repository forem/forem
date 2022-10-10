import {
  codeOfConductPath,
  onboardingPath,
  privacyPath,
  signoutConfirmPath,
  termsPath,
} from '../routes.js.erb';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

const routeForCodeOfConduct = codeOfConductPath();
const routeForOnboarding = onboardingPath();
const routeForPrivacy = privacyPath();
const routeForSignoutConfirm = signoutConfirmPath();
const routeForTerms = termsPath();

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function redirectableLocation() {
  return ![
    routeForOnboarding,
    routeForSignoutConfirm,
    routeForPrivacy,
    '/admin/creator_settings/new',
  ].includes(window.location.pathname);
}

function redirectableCreatorOnboardingLocation() {
  return (
    redirectableLocation() &&
    ![routeForCodeOfConduct, routeForTerms].includes(window.location.pathname)
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
    document.body.dataset.creator === 'true' && !currentUser.saw_onboarding
  );
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;

      if (onboardCreator(currentUser)) {
        if (redirectableCreatorOnboardingLocation()) {
          window.location = `${window.location.origin}/admin/creator_settings/new?referrer=${window.location}`;
        }
      } else if (redirectableLocation() && !onboardingSkippable(currentUser)) {
        window.location = `${window.location.origin}/onboarding?referrer=${window.location}`;
      }
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Error getting user and CSRF Token', error);
    }),
);

function shouldRedirectToOnboarding() {
  // If the value is null in localStorage, that means we should redirect.
  const shouldRedirect =
    localStorage.getItem('shouldRedirectToOnboarding') ?? true;

  return JSON.parse(shouldRedirect);
}

window.InstantClick.on('change', () => {
  getUserDataAndCsrfToken()
    .then(({ currentUser }) => {
      if (
        redirectableCreatorOnboardingLocation() &&
        shouldRedirectToOnboarding() &&
        onboardCreator(currentUser)
      ) {
        window.location = `${window.location.origin}/admin/creator_settings/new?referrer=${window.location}`;
      } else if (
        redirectableLocation() &&
        shouldRedirectToOnboarding() &&
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
