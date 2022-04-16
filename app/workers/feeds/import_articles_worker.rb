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
        users_scope = users_scope.where(id: Users::Setting.with_feed.select(:user_id))
        earlier_than ||= 4.hours.ago
      end

      # For some reason `ActiveSupport::TimeWithZone#is_a?(Time)` evaluates to
      # `true` so this works with any sort of time object
      if earlier_than.is_a?(Time)
        earlier_than = earlier_than.iso8601
      end

      users_scope.select(:id).find_in_batches do |batch|
        arg_lists = batch.map { |user| [user.id, earlier_than] }

        ForUser.perform_bulk(arg_lists)
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
