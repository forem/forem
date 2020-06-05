import { request } from '../../utilities/http';

export async function getChannelDetails(chatChannelMembershipId) {
  const response = await request(
    `/chat_channel_memberships/chat_channel_info/${chatChannelMembershipId}`,
    {
      credentials: 'same-origin',
    },
  );

  return response.json();
}

export async function updatePersonalChatChannelNotificationSettings(
  membershipId,
  notificationBadge,
) {
  const response = await request(
    `/chat_channel_memberships/update_membership/${membershipId}`,
    {
      method: 'PATCH',
      body: {
        chat_channel_membership: {
          show_global_badge_notification: notificationBadge,
        },
      },
      credentials: 'same-origin',
    },
  );

  return response.json();
}

export async function rejectChatChannelJoiningRequest(
  channelId,
  membershipId,
  membershipStatus,
) {
  const response = await request(
    `/chat_channel_memberships/remove_membership`,
    {
      method: 'POST',
      body: {
        status: membershipStatus || 'pending',
        chat_channel_id: channelId,
        membership_id: membershipId,
      },
      credentials: 'same-origin',
    },
  );

  return response.json();
}

export async function acceptChatChannelJoiningRequest(channelId, membershipId) {
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

export async function updateChatChannelDescription(
  channelId,
  description,
  discoverable,
) {
  const response = await request(`/chat_channels/update_channel/${channelId}`, {
    method: 'PATCH',
    body: { chat_channel: { description, discoverable } },
    credentials: 'same-origin',
  });

  return response.json();
}

export async function sendChatChannelInvitation(
  channelId,
  invitationUsernames,
) {
  const response = await request(
    `/chat_channel_memberships/create_membership_request`,
    {
      method: 'POST',
      body: {
        chat_channel_membership: {
          chat_channel_id: channelId,
          invitation_usernames: invitationUsernames,
        },
      },
      credentials: 'same-origin',
    },
  );

  return response.json();
}

export async function leaveChatChannelMembership(membershipId) {
  const response = await request(
    `/chat_channel_memberships/leave_membership/${membershipId}`,
    {
      method: 'PATCH',

      credentials: 'same-origin',
    },
  );

  return response.json();
}
