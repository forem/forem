module Search
  class ChatChannelMembershipEsSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(chat_channel_membership_id)
      chat_channel_membership = ::ChatChannelMembership.find_by(id: chat_channel_membership_id)

      if chat_channel_membership
        chat_channel_membership.index_to_elasticsearch_inline
      else
        Search::ChatChannelMembership.delete_document(chat_channel_membership_id)
      end
    end
  end
end
