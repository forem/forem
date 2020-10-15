module DataUpdateScripts
  class NullifyOrphanedPageViewsByUser
    def run
      # Nullify all PageViews belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          UPDATE page_views
          SET user_id = NULL
          WHERE user_id IS NOT NULL
          AND user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
