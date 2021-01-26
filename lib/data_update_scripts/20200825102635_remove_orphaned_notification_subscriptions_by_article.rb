module DataUpdateScripts
  class RemoveOrphanedNotificationSubscriptionsByArticle
    def run
      # Delete all NotificationSubscriptions belonging to Articles that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM notification_subscriptions
          WHERE notifiable_type = 'Article'
          AND notifiable_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
