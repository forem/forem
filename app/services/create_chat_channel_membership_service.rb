class CreateChatChannelMembershipService < ApplicationService
  def initialize(chat_channel, current_user)
    @chat_channel = chat_channel
    @user = current_user
  end

  attr_accessor :chat_channel, :user

  def perform
    membership = ChatChannelMembership.new(user_id: user.id, chat_channel_id: chat_channel.id)
    membership.save
    membership
  end
end
