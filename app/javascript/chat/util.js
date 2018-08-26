import 'intersection-observer';
import { sendKeys } from './actions';

export function getCsrfToken(doc = document) {
  // TODO: It's not documented what the behaviour is supposed to be if there is no CSRF token.
  const element = doc.querySelector(`meta[name='csrf-token']`);

  return element !== null ? element.content : undefined;
}

const getWaitOnUserDataHandler = ({ resolve, reject, waitTime = 20 }) => {
  let i = 0;

  return function waitingOnUserData() {
    // is not the right approach, but baby steps.
    if (i === 3000) {
      reject(new Error("Couldn't find user data on page."));
      return;
    }

    const userData = document.body.getAttribute('data-user');
    const csrfToken = getCsrfToken();

    if (userData && csrfToken !== undefined) {
      const currentUser = JSON.parse(userData);

      resolve({ currentUser, csrfToken });
      return;
    }

    i += waitTime;
    setTimeout(waitingOnUserData, waitTime);
  };
};

export function getUserDataAndCsrfToken() {
  return new Promise((resolve, reject) => {
    getWaitOnUserDataHandler({ resolve, reject })();
  });
}

export function scrollToBottom() {
  const element = document.getElementById('messagelist');
  element.scrollTop = element.scrollHeight;
}

export function setupObserver(callback) {
  const sentinel = document.querySelector('#messagelist__sentinel');
  const somethingObserver = new IntersectionObserver(callback, {
    threshold: [0, 1],
  });
  somethingObserver.observe(sentinel);
}

export function hideMessages(messages, userId) {
  const cleanedMessages = Object.keys(messages).reduce(
    (accumulator, channelId) => {
      const newMessages = messages[channelId].map(message => {
        if (message.user_id === userId) {
          const messageClone = Object.assign({ type: 'hidden' }, message);
          messageClone.message = '<message removed>';
          messageClone.messageColor = 'lightgray';
          return messageClone;
        }
        return message;
      });
      return { ...accumulator, [channelId]: newMessages };
    },
    {},
  );
  return cleanedMessages;
}

export function adjustTimestamp(timestamp) {
  let time = new Date(timestamp);
  const options = {
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
  };
  time = new Intl.DateTimeFormat('en-US', options).format(time);
  return time;
}

export function setupNotifications() {
  navigator.serviceWorker.ready.then(serviceWorkerRegistration => {
    serviceWorkerRegistration.pushManager
      .getSubscription()
      .then(subscription => {
        if (subscription) {
          return subscription;
        }
        return serviceWorkerRegistration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: window.vapidPublicKey,
        });
      })
      .then(subscription => {
        sendKeys(subscription.toJSON(), null, null);
      });
  });
}

export function getNotificationState() {
  // Not yet ready
  if (!window.location.href.includes('ask-for-notifications')) {
    return 'dont-ask';
  }

  // Let's check if the browser supports notifications
  if (!('Notification' in window)) {
    return 'not-supported';
  } else if (Notification.permission === 'granted') {
    setupNotifications();
    return 'granted';
  } else if (Notification.permission !== 'denied') {
    return 'waiting-permission';
  }
  return 'denied';
}
