module DataUpdateScripts
  class RemoveOrphanedAhoyRows
    def run
      user_ids = User.ids

      # Delete all Ahoy::Events belonging to a user that does not exist anymore
      Ahoy::Event.where.not(user_id: nil).where.not(user_id: user_ids).find_each(&:destroy)

      # Delete all Ahoy::Messages belonging to a user that does not exist anymore
      Ahoy::Message.where.not(user_id: nil).where.not(user_id: user_ids).find_each(&:destroy)

      # Delete all Ahoy::Visits belonging to a user that does not exist anymore
      Ahoy::Visit.where.not(user_id: nil).where.not(user_id: user_ids).find_each(&:destroy)
    end
  end
end
