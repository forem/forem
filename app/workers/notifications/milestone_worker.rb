module Notifications
  class MilestoneWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    def perform(type, article_id)
      article = Article.find_by(id: article_id)
      return unless article

      Notifications::Milestone::Send.call(type, article)
    end
  end
end
