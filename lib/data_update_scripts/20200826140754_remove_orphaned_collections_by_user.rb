module DataUpdateScripts
  class RemoveOrphanedCollectionsByUser
    def run
      # Delete all Collections belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM collections
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
