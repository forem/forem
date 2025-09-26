module Notifications
  class SubforemChangeNotificationWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(article_id, old_subforem_id, new_subforem_id)
      article = Article.find_by(id: article_id)
      return unless article

      Notifications::SubforemChangeNotification::Send.call(
        article: article,
        old_subforem_id: old_subforem_id,
        new_subforem_id: new_subforem_id,
      )
    end
  end
end
