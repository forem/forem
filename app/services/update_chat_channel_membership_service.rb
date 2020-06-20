class UpdateChatChannelMembershipService < ApplicationService
  def initialize(chat_channel, membership, params)
    @chat_channel = chat_channel
    @membership = membership
    @params = params
  end

  attr_accessor :chat_channel, :membership, :params

  # @TODO: Add dynamic content
  def perform
    membership.update(params)
    membership
  end
end
