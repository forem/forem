module DataUpdateScripts
  class RemoveOrphanedReactionsByUser
    def run
      # Delete all Reactions belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM reactions
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
