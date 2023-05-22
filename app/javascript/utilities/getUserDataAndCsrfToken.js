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

  return function waitingOnUserData() {
    if (totalTimeWaiting === 3000) {
      if (!safe) {
        reject(new Error("Couldn't find user data on page."));
        return;
      } 
        resolve({ user, csrfToken });
        return;
      
    }

    const csrfToken = getCsrfToken(document);
    const { user } = document.body.dataset;

    if (user && csrfToken !== undefined) {
      const currentUser = JSON.parse(user);

      resolve({ currentUser, csrfToken });
      return;
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
