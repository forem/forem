export function getAllMessages(successCb, failureCb) {
  fetch('/chat_channels/1', {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function sendMessage(message, successCb, failureCb) {
  fetch('/messages', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        message_html: message,
        user_id: window.currentUser.id,
        chat_channel_id: '1',
      },
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function conductModeration(message, successCb, failureCb) {
  fetch('/chat_channels/1/moderate', {
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
