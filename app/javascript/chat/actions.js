export function getAllMessages(channelId, successCb, failureCb) {
  fetch(`/chat_channels/${channelId}`, {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function sendMessage(activeChannelId, message, successCb, failureCb) {
  fetch('/messages', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        message_markdown: message,
        user_id: window.currentUser.id,
        chat_channel_id: activeChannelId,
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
  const client = algoliasearch(props.algoliaId, props.algoliaKey);
  const index = client.initIndex(props.algoliaIndex);
  const filters = {
    ...{
      hitsPerPage: 30 + paginationNumber,
      page: paginationNumber,
    },
    ...additionalFilters,
  };
  index.search(query, filters).then(content => {
    const channels = content.hits;
    if (
      retrievalID === null ||
      content.hits.filter(e => e.chat_channel_id === retrievalID).length === 1
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
        .then(response => response.json())
        .then(json => {
          channels.unshift(json);
          successCb(channels, query);
        });
    }
  });
}

export function sendKeys(subscription, successCb, failureCb) {
  fetch(`/push_notification_subscriptions`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      subscription,
    }),
    credentials: 'same-origin',
  })
    .then(response => response.json())
    .then(successCb)
    .catch(failureCb);
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
