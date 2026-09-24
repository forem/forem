module Users
  class UpdateUserReadingListActivityWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority, retry: 10, lock: :until_executing, on_conflict: :replace

    def perform(user_id)
      return unless user_id

      UserActivity.update_reading_list_articles_for(user_id)
    end
  end
end
