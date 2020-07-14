import { request } from '../../utilities/http';

/**
 *
 * @param {channelId} channelId
 * @param {membershipId} membershipId
 */
export async function rejectJoiningRequest(channelId, membershipId) {
  const response = await request(
    `/chat_channel_memberships/remove_membership`,
    {
      method: 'POST',
      body: {
        status: 'pending',
        chat_channel_id: channelId,
        membership_id: membershipId,
      },
      credentials: 'same-origin',
    },
  );

  return response.json();
}

/**
 * This function is responsible for the Accept joining request for channel
 * @param {number} channelId
 * @param {number} membershipId
 */

export async function acceptJoiningRequest(channelId, membershipId) {
  const response = await request(`/chat_channel_memberships/add_membership`, {
    method: 'POST',
    body: {
      chat_channel_id: channelId,
      membership_id: membershipId,
      chat_channel_membership: {
        user_action: 'accept',
      },
    },
    credentials: 'same-origin',
  });

  return response.json();
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
 */

export async function getChannelRequestInfo() {
  const response = await request(`/channel_request_info/`, {
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
