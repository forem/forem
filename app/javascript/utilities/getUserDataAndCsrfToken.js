export function getCsrfToken() {
  const element = document.querySelector(`meta[name='csrf-token']`);

  return element !== null ? element.content : undefined;
}

const getWaitOnUserDataHandler = ({
  resolve,
  reject,
  safe = false,
  waitTime = 20,
}) => {
  let totalTimeWaiting = 0;
  const maxWaitTime = 5000; // Extended from 3000ms to 5000ms for slower networks

  return function waitingOnUserData() {
    if (totalTimeWaiting >= maxWaitTime) {
      if (!safe) {
        reject(new Error("Couldn't find user data on page."));
        return;
      } 
        resolve({ user: null, csrfToken: getCsrfToken(document) });
        return;
      
    }

    const csrfToken = getCsrfToken(document);
    const { user } = document.body.dataset;

    if (user && csrfToken !== undefined) {
      try {
        const currentUser = JSON.parse(user);
        resolve({ currentUser, csrfToken });
        return;
      } catch (error) {
        console.error('Error parsing user data:', error);
        reject(new Error('Failed to parse user data'));
        return;
      }
    }

    totalTimeWaiting += waitTime;
    setTimeout(waitingOnUserData, waitTime);
  };
};

export function getUserDataAndCsrfTokenSafely() {
  return new Promise((resolve, reject) => {
    const safe = true;
    getWaitOnUserDataHandler({ resolve, reject, safe })();
  });
}

export function getUserDataAndCsrfToken() {
  return new Promise((resolve, reject) => {
    getWaitOnUserDataHandler({ resolve, reject })();
  });
}
