module Notifications
  class CoAuthorWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace, retry: 10

    def perform(article_id, removed_user_ids = [])
      Notifications::CoAuthor::Remove.call(article_id, removed_user_ids)

      article = Article.find_by(id: article_id)
      return unless article

      Notifications::CoAuthor::Send.call(article)
    end
  end
end
