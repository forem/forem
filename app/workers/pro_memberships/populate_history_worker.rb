module ProMemberships
  class PopulateHistoryWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user&.pro?

      user.page_views.reindex!
    end
  end
end
