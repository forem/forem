module Feeds
  class ImportArticlesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_ids = [])
      user_ids = Array.wrap(user_ids)

      users = if user_ids.present?
                User.where(id: user_ids)
              else
                User.with_feed
              end

      ::Feeds::Import.call(users: users)
    end
  end
end
