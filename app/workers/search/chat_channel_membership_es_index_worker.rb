module Search
  class ChatChannelMembershipEsIndexWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(chat_channel_membership_id)
      chat_channel_membership = ::ChatChannelMembership.find(chat_channel_membership_id)
      chat_channel_membership.index_to_elasticsearch_inline
    end
  end
end
