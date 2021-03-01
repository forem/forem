module DataUpdateScripts
  class RemoveOrphanedArticlesByUser
    def run
      # Delete all Articles belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM articles
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
