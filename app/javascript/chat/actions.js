import { fetchSearch } from '../src/utils/search';

export function getAllMessages(channelId, messageOffset, successCb, failureCb) {
  fetch(`/chat_channels/${channelId}?message_offset=${messageOffset}`, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function sendMessage(messageObject, successCb, failureCb) {
  fetch('/messages', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        message_markdown: messageObject.message,
        user_id: window.currentUser.id,
        chat_channel_id: messageObject.activeChannelId,
        mentioned_users_id: messageObject.mentionedUsersId,
      },
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function editMessage(editedMessage, successCb, failureCb) {
  fetch(`/messages/${editedMessage.id}`, {
    method: 'PATCH',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        message_markdown: editedMessage.message,
        user_id: window.currentUser.id,
        chat_channel_id: editedMessage.activeChannelId,
      },
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function sendOpen(activeChannelId, successCb, failureCb) {
  fetch(`/chat_channels/${activeChannelId}/open`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({}),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function conductModeration(
  activeChannelId,
  message,
  successCb,
  failureCb,
) {
  fetch(`/chat_channels/${activeChannelId}/moderate`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      chat_channel: {
        command: message,
      },
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getChannels(
  query,
  retrievalID,
  props,
  paginationNumber,
  additionalFilters,
  successCb,
  _failureCb,
) {
  const dataHash = {};
  if (additionalFilters.filters) {
    const [key, value] = additionalFilters.filters.split(':');
    dataHash[key] = value;
  }
  dataHash.per_page = 30;
  dataHash.page = paginationNumber;
  dataHash.channel_text = query;

  const responsePromise = fetchSearch('chat_channels', dataHash);

  return responsePromise.then(response => {
    const channels = response.result;
    if (
      retrievalID === null ||
      channels.filter(e => e.chat_channel_id === retrievalID).length === 1
    ) {
      successCb(channels, query);
    } else {
      fetch(
        `/chat_channel_memberships/find_by_chat_channel_id?chat_channel_id=${retrievalID}`,
        {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          credentials: 'same-origin',
        },
      )
        .then(individualResponse => individualResponse.json())
        .then(json => {
          channels.unshift(json);
          successCb(channels, query);
        });
    }
  });
}

export function getUnopenedChannelIds(successCb) {
  fetch('/chat_channels?state=unopened_ids', {
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(json => {
      successCb(json.unopened_ids);
    });
}

export function getTwilioToken(videoChannelName, successCb, failureCb) {
  fetch(`/twilio_tokens/${videoChannelName}`, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getContent(url, successCb, failureCb) {
  fetch(url, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getJSONContents(url, successCb, failureCb) {
  fetch(url, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getChannelInvites(successCb, failureCb) {
  fetch('/chat_channels?state=pending', {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function sendChannelInviteAction(id, action, successCb, failureCb) {
  fetch(`/chat_channel_memberships/${id}`, {
    method: 'PUT',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      chat_channel_membership: {
        user_action: action,
      },
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function deleteMessage(messageId, successCb, failureCb) {
  fetch(`/messages/${messageId}`, {
    method: 'DELETE',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        user_id: window.currentUser.id,
      },
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}
