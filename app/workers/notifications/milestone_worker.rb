module Notifications
  class MilestoneWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform(type, article_id, service = Notifications::Milestone::Send)
      article = Article.find_by(id: article_id)
      return unless article

      service.call(type, article)
    end
  end
end
