class ChatChannelUpdateService < ApplicationService
  attr_accessor :chat_channel, :params

  def initialize(chat_channel, params)
    @chat_channel = chat_channel
    @params = params
  end

  def perform
    chat_channel.update(params)
    chat_channel
  end
end
