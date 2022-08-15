module Users
  class MergeSyncWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      # [@practicaldev/sre]: These saves will do a lot of duplicate work. Since we are not merging users
      # a lot I think this is fine for now and can be optimized in the future when we
      # decrease our dependency on callbacks.
      resave_content(user.articles)
      resave_content(user.comments)
      resave_content(user.reactions.readinglist)
      resave_content(Reaction.for_articles(user.articles.ids).readinglist)
    end

    private

    def resave_content(content_ar_relation)
      # Triggers callbacks to ensure caches are busted, scores updated, and docs
      # are reindexed with the correct new user
      content_ar_relation.find_each(&:save)
    end
  end
end
