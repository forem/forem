module DataUpdateScripts
  class RemoveOrphanedPolls
    def run
      # Delete all Polls belonging to Articles that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM polls
          WHERE article_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
