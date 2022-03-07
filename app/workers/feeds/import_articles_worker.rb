module Feeds
  class ImportArticlesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10, lock: :until_and_while_executing

    # NOTE: [@rhymes] we need to default earlier_than to `nil` because sidekiq-cron,
    # by using YAML to define jobs arguments does not support datetimes evaluated
    # at runtime
    def perform(user_ids = [], earlier_than = nil)
      users_scope = User

      if user_ids.present?
        users_scope = users_scope.where(id: user_ids)
        # we assume that forcing a single import should not take into account
        # the last time a feed was fetched at
        earlier_than = nil
      else
        earlier_than ||= 4.hours.ago
      end

      users_scope.select(:id).find_in_batches do |batch|
        ids = batch.map { |user| [user.id] }

        ForUser.perform_bulk ids, earlier_than
      end
    end

    class ForUser
      include Sidekiq::Worker

      def perform(user_ids, earlier_than)
        users_scope = User.where(id: user_ids)

        ::Feeds::Import.call(users_scope: users_scope, earlier_than: earlier_than)
      end
    end
  end
end
