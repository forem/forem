module Feeds
  class ImportArticlesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_ids = [], earlier_than = nil)
      users = user_ids.present? ? User.where(id: user_ids) : nil

      ::Feeds::Import.call(users: users, earlier_than: earlier_than)
    end
  end
end
