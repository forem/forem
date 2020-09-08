module ChatChannels
  class IndexesMembershipsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, lock: :until_executing

    def perform(chat_channel_id)
      chat_channel = ChatChannel.find(chat_channel_id)
      chat_channel.chat_channel_memberships.each(&:index_to_elasticsearch)
    end
  end
end
