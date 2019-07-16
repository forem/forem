import { getUserDataAndCsrfToken } from '../chat/util';

function redirectableLocation() {
  return (
    window.location.pathname !== '/onboarding' &&
    window.location.pathname !== '/signout_confirm'
  );
}

document.onreadystatechange = () => {
  if (document.readyState === 'complete') {
    getUserDataAndCsrfToken()
      .then(({ currentUser }) => {
        if (redirectableLocation() && !currentUser.saw_onboarding) {
          window.location = `${window.location.origin}/onboarding`;
        }
      })
      .catch(error => {
        // eslint-disable-next-line no-console
        console.error('Error getting user and CSRF Token', error);
      });
  }
};
