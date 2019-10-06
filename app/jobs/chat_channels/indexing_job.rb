# frozen_string_literal: true

module ChatChannels
  class IndexingJob < ApplicationJob
    queue_as :chat_channels_indexing

    def perform(chat_channel_id:)
      chat_channel = ChatChannel.find_by(id: chat_channel_id)

      return unless chat_channel

      chat_channel.index!
    end
  end
end
