module Moderator
  class SinkArticles
    def self.call(user_id)
      # rubocop:disable Lint/UnreachableCode
      # HOTFIX
      # @mstruve: This worker is broken and needs to be fixed. It can inadvertantly
      # bump up scores for a user's articles if they have a lot of good reactions
      # this leads to clumps of articles from the same user in feeds
      return
      Moderator::SinkArticlesWorker.perform_async(user_id)
      # rubocop:enable Lint/UnreachableCode
    end
  end
end
