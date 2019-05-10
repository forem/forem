module Notifications
  class MilestoneJob < ApplicationJob
    queue_as :send_milestone_notification

    def perform(milestone_hash, service = Notifications::Milestone::Send)
      article = Article.find_by(id: milestone_hash[:article_id])
      return unless article

      service.call(milestone_hash[:type], article)
    end
  end
end
