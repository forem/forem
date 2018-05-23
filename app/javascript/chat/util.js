import 'intersection-observer';

export function getUserDataAndCsrfToken() {
  const promise = new Promise((resolve, reject) => {
    let i = 0;
    const waitingOnUserData = setInterval(() => {
      let userData = null;
      const dataUserAttribute = document.body.getAttribute('data-user');
      const meta = document.querySelector("meta[name='csrf-token']");
      if (
        dataUserAttribute &&
        dataUserAttribute !== 'undefined' &&
        dataUserAttribute !== undefined &&
        meta &&
        meta.content !== 'undefined' &&
        meta.content !== undefined
      ) {
        userData = JSON.parse(dataUserAttribute);
      }
      i += 1;
      if (userData) {
        clearInterval(waitingOnUserData);
        resolve(userData);
      } else if (i === 3000) {
        clearInterval(waitingOnUserData);
        reject(new Error("Couldn't find user data on page."));
      }
    }, 5);
  });
  return promise;
}

export function scrollToBottom() {
  const element = document.getElementById('messagelist');
  element.scrollTop = element.scrollHeight;
}

export function setupObserver(callback) {
  const sentinel = document.querySelector('#messagelist__sentinel');
  const somethingObserver = new IntersectionObserver(callback);
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
