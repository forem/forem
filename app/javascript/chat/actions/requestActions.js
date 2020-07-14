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

/**
 * This function will get all the request realted to user and channel
 * @param {number} membershipId
 */

export async function getChannelRequestInfo(membershipId) {
  const response = await request(`/channel_request_info/${membershipId}`, {
    method: 'GET',
    credentials: 'same-origin',
  });

  return response.json();
}

/**
 * This function handle user action on chat channel invitations
 *
 * @param {number} membershipId
 * @param {string} userAction
 */

export async function updateMembership(membershipId, userAction) {
  const response = await request(`/chat_channel_memberships/${membershipId}`, {
    method: 'PUT',
    credentials: 'same-origin',
    body: {
      chat_channel_membership: {
        user_action: userAction,
      },
    },
  });

  return response.json();
}
