module Notifications
  class MentionJob < ApplicationJob
    queue_as :send_new_mention_notification
    
    def perform(mention_id, service = NewMention::Send)
      mention = Mention.find(mention_id)
      return unless mention

      service.call(mention)
    end
  end
end