module DataUpdateScripts
  class RemoveOrphanedPageViewsByUser
    def run
      # Delete all Collections belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM page_views
          WHERE user_id IS NOT NULL
          AND user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
