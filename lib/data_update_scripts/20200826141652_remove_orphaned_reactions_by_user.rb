module DataUpdateScripts
  class RemoveOrphanedReactionsByUser
    def run
      # Delete all Reactions belonging to Users that don't exist anymore
      Reaction.where("user_id NOT IN (SELECT id FROM users)").destroy_all
    end
  end
end
