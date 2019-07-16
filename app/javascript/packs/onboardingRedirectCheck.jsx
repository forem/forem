import { getUserDataAndCsrfToken } from '../chat/util';

document.onreadystatechange = () => {
  if (document.readyState === 'complete') {
    getUserDataAndCsrfToken()
      .then(({ currentUser }) => {
        if (
          window.location.pathname !== '/onboarding' &&
          !currentUser.saw_onboarding
        ) {
          window.location = `${window.location.origin}/onboarding`;
        }
      })
      .catch(error => {
        // eslint-disable-next-line no-console
        console.error('Error getting user and CSRF Token', error);
      });
  }
};
