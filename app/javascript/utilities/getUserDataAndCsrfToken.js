const CURRENT_USER_STORAGE_KEY = 'current_user';
const DEFAULT_WAIT_TIME = 20;
const DEFAULT_MAX_WAIT_TIME = 5000; // Extended from 3000ms to 5000ms for slower networks

export function getCsrfToken(doc = document) {
  const element = doc?.querySelector(`meta[name='csrf-token']`);

  return element !== null && element !== undefined ? element.content : undefined;
}

const base64DecodeUnicode = (str) => {
  try {
    return decodeURIComponent(
      atob(str)
        .split('')
        .map((char) => `%${(`00${char.charCodeAt(0).toString(16)}`).slice(-2)}`)
        .join(''),
    );
  } catch (error) {
    console.error('Error decoding cached user data:', error);
    return null;
  }
};

const getCookieValue = (name) => {
  if (typeof document === 'undefined') {
    return null;
  }

  const escapedName = name.replace(/([.*+?^${}()|[\]\\])/g, '\\$1');
  const match = document.cookie.match(
    new RegExp(`(?:^|; )${escapedName}=([^;]*)`),
  );

  return match ? match[1] : null;
};

const getStoredUserString = () => {
  const datasetUser = document?.body?.dataset?.user;
  if (datasetUser) {
    return datasetUser;
  }

  try {
    if (typeof window !== 'undefined' && window.localStorage) {
      const localStorageUser = window.localStorage.getItem(
        CURRENT_USER_STORAGE_KEY,
      );

      if (localStorageUser) {
        return localStorageUser;
      }
    }
  } catch (error) {
    console.error('Error getting cached user from localStorage:', error);
  }

  const cookieValue = getCookieValue(CURRENT_USER_STORAGE_KEY);
  if (cookieValue) {
    const decodedCookie = decodeURIComponent(cookieValue);
    const decodedUser = base64DecodeUnicode(decodedCookie);

    if (decodedUser) {
      return decodedUser;
    }
  }

  return null;
};

const ensureBodyDatasetUser = (userString) => {
  if (!document?.body?.dataset?.user) {
    document.body.dataset.user = userString;
  }
};

const resolveWithSerializedUser = ({ resolve, reject, userString, csrfToken }) => {
  try {
    const currentUser = JSON.parse(userString);
    ensureBodyDatasetUser(userString);
    resolve({ currentUser, csrfToken });
  } catch (error) {
    console.error('Error parsing user data:', error);
    reject(new Error('Failed to parse user data'));
  }
};

const getTimingOptions = (options = {}) => {
  if (!options || typeof options !== 'object') {
    return {};
  }

  const timingOptions = {};
  if ('waitTime' in options) {
    timingOptions.waitTime = options.waitTime;
  }
  if ('maxWaitTime' in options) {
    timingOptions.maxWaitTime = options.maxWaitTime;
  }

  return timingOptions;
};

const getWaitOnUserDataHandler = ({
  resolve,
  reject,
  safe = false,
  waitTime = DEFAULT_WAIT_TIME,
  maxWaitTime = DEFAULT_MAX_WAIT_TIME,
}) => {
  let totalTimeWaiting = 0;

  return function waitingOnUserData() {
    const csrfToken = getCsrfToken(document);
    const userString = getStoredUserString();

    if (userString && csrfToken !== undefined) {
      resolveWithSerializedUser({ resolve, reject, userString, csrfToken });
      return;
    }

    if (totalTimeWaiting >= maxWaitTime) {
      if (safe) {
        resolve({ currentUser: null, csrfToken });
        return;
      }

      reject(new Error("Couldn't find user data on page."));
      return;
    }

    totalTimeWaiting += waitTime;
    setTimeout(waitingOnUserData, waitTime);
  };
};

export function getUserDataAndCsrfTokenSafely(options = {}) {
  const timingOptions = getTimingOptions(options);

  return new Promise((resolve, reject) => {
    getWaitOnUserDataHandler({ resolve, reject, safe: true, ...timingOptions })();
  });
}

export function getUserDataAndCsrfToken(options = {}) {
  const timingOptions = getTimingOptions(options);

  return new Promise((resolve, reject) => {
    getWaitOnUserDataHandler({ resolve, reject, ...timingOptions })();
  });
}
