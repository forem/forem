module ProMemberships
  class PopulateHistoryJob < ApplicationJob
    queue_as :pro_memberships_populate_history

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user&.pro?

      user.page_views.reindex!
    end
  end
end
