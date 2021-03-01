module DataUpdateScripts
  class RemoveOrphanedBufferUpdatesByArticle
    def run
      # Delete all BufferUpdates belonging to Articles that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM buffer_updates
          WHERE article_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
