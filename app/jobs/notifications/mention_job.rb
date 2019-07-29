module Notifications
  class MentionJob < ApplicationJob
    queue_as :send_new_mention_notification

    def perform(mention_id, service = NewMention::Send)
      mention = Mention.find_by(id: mention_id)
      service.call(mention) if mention
    end
  end
end
