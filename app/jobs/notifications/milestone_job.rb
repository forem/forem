module Notifications
  class MilestoneJob < ApplicationJob
    queue_as :send_milestone_notification

    def perform(type, article_id, service = Notifications::Milestone::Send)
      article = Article.find_by(id: article_id)
      return unless article

      service.call(type, article)
    end
  end
end
