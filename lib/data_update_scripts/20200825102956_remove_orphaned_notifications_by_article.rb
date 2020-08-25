module DataUpdateScripts
  class RemoveOrphanedNotificationsByArticle
    def run
      # Delete all Notifications related to Articles that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM notifications
          WHERE notifiable_type = 'Article'
          AND notifiable_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
