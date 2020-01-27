module Users
  class EstimateDefaultLanguageWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      Users::EstimateDefaultLanguage.call(user) if user
    end
  end
end
