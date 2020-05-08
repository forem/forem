import 'intersection-observer';

export function getCsrfToken() {
  const element = document.querySelector(`meta[name='csrf-token']`);

  return element !== null ? element.content : undefined;
}

const getWaitOnUserDataHandler = ({ resolve, reject, waitTime = 20 }) => {
  let totalTimeWaiting = 0;

  return function waitingOnUserData() {
    if (totalTimeWaiting === 3000) {
      reject(new Error("Couldn't find user data on page."));
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

export const getCurrentUser = () => {
  const { user } = document.body.dataset;
  return JSON.parse(user);
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
      const newMessages = messages[channelId].map((message) => {
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

export const channelSorter = (channels, currentUserId, filterQuery) => {
  const activeChannels = channels.filter(
    (channel) =>
      channel.viewable_by === currentUserId && channel.status === 'active',
  );

  const joiningChannels = channels.filter(
    (channel) =>
      channel.viewable_by === currentUserId &&
      channel.status === 'joining_request',
  );

  const activeChannelIds = [
    ...new Set(activeChannels.map((x) => x.chat_channel_id)),
  ];

  const joiningChannelIds = [
    ...new Set(joiningChannels.map((x) => x.chat_channel_id)),
  ];

  const discoverableChannels = channels
    .filter(
      (channel) =>
        (channel.viewable_by === currentUserId &&
          channel.status === 'joining_request' &&
          filterQuery) ||
        channel.viewable_by !== currentUserId,
    )
    .filter((channel) => !activeChannelIds.includes(channel.chat_channel_id))
    .filter((channel) =>
      !!(joiningChannelIds.includes(channel.chat_channel_id) &&
      channel.viewable_by === currentUserId),
    );

  return { activeChannels, discoverableChannels };
};
