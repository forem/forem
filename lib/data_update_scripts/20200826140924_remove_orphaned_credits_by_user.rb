module DataUpdateScripts
  class RemoveOrphanedCreditsByUser
    def run
      # Delete all Credits belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM credits
          WHERE user_id IS NOT NULL
          AND user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
