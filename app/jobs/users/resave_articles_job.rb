module Users
  class ResaveArticlesJob < ApplicationJob
    queue_as :users_resave_articles

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      user.resave_articles
    end
  end
end
