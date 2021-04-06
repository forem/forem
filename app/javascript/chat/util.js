import { fetchSearch } from '../utilities/search';

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
  const sentinel = document.getElementById('messagelist__sentinel');
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
    (channel) => channel.status === 'joining_request',
  );
  const ChannelIds = [
    [...new Set(activeChannels.map((x) => x.chat_channel_id))],
    [...new Set(joiningChannels.map((x) => x.chat_channel_id))],
  ];
  const discoverableChannels = channels
    .filter(
      (channel) =>
        (channel.status === 'joining_request' && filterQuery) ||
        (!ChannelIds[1].includes(channel.chat_channel_id) &&
          channel.viewable_by !== currentUserId),
    )
    .filter((channel) => !ChannelIds[0].includes(channel.chat_channel_id));
  return { activeChannels, discoverableChannels };
};

export const createDataHash = (additionalFilters, searchParams) => {
  const dataHash = {};
  if (additionalFilters.filters) {
    const [key, value] = additionalFilters.filters.split(':');
    dataHash[key] = value;
  }
  dataHash.per_page = 30;
  dataHash.page = searchParams.paginationNumber;
  if (searchParams.searchType === 'discoverable') {
    dataHash.user_id = 'all';
  }
  return fetchSearch('chat_channels', dataHash);
};
