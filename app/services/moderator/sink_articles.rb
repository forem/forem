module Moderator
  class SinkArticles
    def self.call(user_id)
      Moderator::SinkArticlesWorker.perform_async(user_id)
    end
  end
end
