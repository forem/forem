import { request } from '../../utilities/http';

export function rejectJoiningRequest(
  channelId,
  membershipId,
  successCb,
  failureCb,
) {
  request(`/chat_channel_memberships/remove_membership`, {
    method: 'POST',
    body: {
      status: 'pending',
      chat_channel_id: channelId,
      membership_id: membershipId,
    },
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function acceptJoiningRequest(
  channelId,
  membershipId,
  successCb,
  failureCb,
) {
  request(`/chat_channel_memberships/add_membership`, {
    method: 'POST',
    body: {
      chat_channel_id: channelId,
      membership_id: membershipId,
      chat_channel_membership: {
        user_action: 'accept',
      },
    },
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function sendChannelRequest(id, successCb, failureCb) {
  request(`/join_chat_channel`, {
    method: 'POST',
    body: {
      chat_channel_membership: {
        chat_channel_id: id,
      },
    },
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}
