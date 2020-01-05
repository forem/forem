module ChatChannels
  class IndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(chat_channel_id:)
      chat_channel = ChatChannel.find_by(id: chat_channel_id)
      return unless chat_channel

      chat_channel.index!
    end
  end
end
