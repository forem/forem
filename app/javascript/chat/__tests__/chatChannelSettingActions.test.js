import fetch from 'jest-fetch-mock';
import {
  getChannelDetails,
  updatePersonalChatChannelNotificationSettings,
  rejectChatChannelJoiningRequest,
  acceptChatChannelJoiningRequest,
  updateChatChannelDescription,
  sendChatChannelInvitation,
  leaveChatChannelMembership,
  updateMembershipRole,
} from '../actions/chat_channel_setting_actions';

/* global globalThis */

describe('Chat channel API requests', () => {
  const csrfToken = 'this-is-a-csrf-token';
  const chanChannelMembershipId = 26; // Just a random chatChannelMembershipId ID.
  const channelId = 2;

  beforeAll(() => {
    globalThis.fetch = fetch;
    globalThis.getCsrfToken = async () => csrfToken;
  });
  afterAll(() => {
    delete globalThis.fetch;
    delete globalThis.getCsrfToken;
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('get chat channel info', () => {
    it('should have success response with channel details', async () => {
      const response = {
        success: true,
        current_membership: {
          user_id: 1,
          id: 2,
          chat_channel_id: 1,
          status: 'active',
          role: 'mod',
        },
        chat_channel: {
          name: 'dummy channel',
          description: 'some dummy description',
          discoverable: true,
          status: 'active',
        },
        memberships: {
          active_memberships: [],
          pending_memberships: [],
          requested_memberships: [],
        },
      };

      fetch.mockResponse(JSON.stringify(response));

      const chatChannelDetails = await getChannelDetails(
        chanChannelMembershipId,
      );
      expect(chatChannelDetails).toEqual(response);
    });

    it('not found channel', async () => {
      const response = {
        success: false,
        message: 'not found',
      };

      fetch.mockResponse(JSON.stringify(response));

      const chatChannelDetails = await getChannelDetails(
        chanChannelMembershipId,
      );
      expect(chatChannelDetails).toEqual(response);
    });
  });

  describe('Update chat channel notification', () => {
    it('should have success', async () => {
      const response = { success: true, message: 'user settings updated' };
      fetch.mockResponse(JSON.stringify(response));

      const updateProfile = await updatePersonalChatChannelNotificationSettings(
        chanChannelMembershipId,
        true,
      );
      expect(updateProfile).toEqual(response);
    });

    it('should return not found error', async () => {
      const response = { success: false, message: 'not found' };
      fetch.mockResponse(JSON.stringify(response));

      const updateProfile = await updatePersonalChatChannelNotificationSettings(
        '',
        true,
      );
      expect(updateProfile).toEqual(response);
    });
  });

  describe('reject chat channel membership', () => {
    it('should have success', async () => {
      const response = { success: true, message: 'user removed' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await rejectChatChannelJoiningRequest(
        channelId,
        chanChannelMembershipId,
        'pending',
      );
      expect(result).toEqual(response);
    });

    it('should return not found error', async () => {
      const response = { success: false, message: 'not found' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await rejectChatChannelJoiningRequest('', '', 'pending');
      expect(result).toEqual(response);
    });
  });

  describe('Accept chat channel membership', () => {
    it('should have success', async () => {
      const response = { success: true, message: 'added to chat channel' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await acceptChatChannelJoiningRequest(
        channelId,
        chanChannelMembershipId,
      );
      expect(result).toEqual(response);
    });

    it('should return not found error', async () => {
      const response = { success: false, message: 'not found' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await acceptChatChannelJoiningRequest('', '');
      expect(result).toEqual(response);
    });
  });

  describe('update chat channel', () => {
    it('should have success', async () => {
      const response = { success: true, message: 'channel is  updated' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await updateChatChannelDescription(
        channelId,
        'some description',
        true,
      );
      expect(result).toEqual(response);
    });
  });

  describe('Send inbvitation for join chat channel', () => {
    it('should have success', async () => {
      const response = { success: true, message: 'added to chat channel' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await sendChatChannelInvitation(channelId, 'dummyuser');
      expect(result).toEqual(response);
    });

    it('should not send any invitation', async () => {
      const response = { success: true, message: 'no invitation sent' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await sendChatChannelInvitation(channelId, '');
      expect(result).toEqual(response);
    });

    it('should return not found error', async () => {
      const response = { success: false, message: 'not found' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await sendChatChannelInvitation('', '');
      expect(result).toEqual(response);
    });
  });

  describe('Leave chat channel', () => {
    it('should have success', async () => {
      const response = { success: true, message: 'user left the channel' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await leaveChatChannelMembership(chanChannelMembershipId);
      expect(result).toEqual(response);
    });

    it('should return not found error', async () => {
      const response = { success: false, message: 'not found' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await leaveChatChannelMembership('');
      expect(result).toEqual(response);
    });
  });

  describe('Update the membership role', () => {
    it('should have the success response', async () => {
      const response = { success: true, message: 'user membership is updated' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await updateMembershipRole(
        chanChannelMembershipId,
        channelId,
        'mod',
      );
      expect(result).toEqual(response);
    });

    it('should return the not found', async () => {
      const response = { success: false, message: 'not found' };
      fetch.mockResponse(JSON.stringify(response));

      const result = await updateMembershipRole('', '', 'mod');
      expect(result).toEqual(response);
    });
  });
});
