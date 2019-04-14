module Users
  class EstimateDefaultLanguageJob < ApplicationJob
    queue_as :users_estimate_language

    def perform(user_id, service = Users::EstimateDefaultLanguage)
      user = User.find_by(id: user_id)
      service.call(user) if user
    end
  end
end
