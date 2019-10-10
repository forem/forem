# frozen_string_literal: true

module ChatChannels
  class IndexJob < ApplicationJob
    queue_as :chat_channels_index

    def perform(chat_channel_id:)
      chat_channel = ChatChannel.find(chat_channel_id)
      chat_channel.index!
    end
  end
end
