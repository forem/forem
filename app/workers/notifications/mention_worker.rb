module Notifications
  class MentionWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform(mention_id)
      mention = Mention.find_by(id: mention_id)
      Notifications::NewMention::Send.call(mention) if mention
    end
  end
end
