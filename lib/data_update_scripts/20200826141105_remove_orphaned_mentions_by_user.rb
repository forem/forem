module DataUpdateScripts
  class RemoveOrphanedMentionsByUser
    def run
      # Delete all Mentions belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM mentions
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
