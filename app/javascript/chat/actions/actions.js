import { createDataHash } from '../util';

export function getAllMessages(channelId, messageOffset, successCb, failureCb) {
  fetch(`/chat_channels/${channelId}?message_offset=${messageOffset}`, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then((response) => response.json())
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
    .then((response) => response.json())
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
    .then((response) => response.json())
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
    .then((response) => response.json())
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
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getChannels(
  searchParams,
  additionalFilters,
  successCb,
  _failureCb,
) {
  return createDataHash(additionalFilters, searchParams).then((response) => {
    if (
      searchParams.retrievalID === null ||
      response.result.filter(
        (e) => e.chat_channel_id === searchParams.retrievalID,
      ).length === 1
    ) {
      successCb(response.result, searchParams.query);
    } else {
      fetch(
        `/chat_channel_memberships/find_by_chat_channel_id?chat_channel_id=${searchParams.retrievalID}`,
        {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          credentials: 'same-origin',
        },
      )
        .then((individualResponse) => individualResponse.json())
        .then((json) => {
          response.result.unshift(json);
          successCb(response.result, searchParams.query);
        });
    }
  });
}

export function getUnopenedChannelIds(successCb) {
  fetch('/chat_channels?state=unopened_ids', {
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((json) => {
      successCb(json.unopened_ids);
    });
}

export function getContent(url, successCb, failureCb) {
  fetch(url, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getJSONContents(url, successCb, failureCb) {
  fetch(url, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getChannelInvites(successCb, failureCb) {
  fetch('/chat_channels?state=pending', {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getJoiningRequest(successCb, failureCb) {
  fetch('/chat_channels?state=joining_request', {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then((response) => response.json())
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
    .then((response) => response.json())
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
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}
