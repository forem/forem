module DataUpdateScripts
  class RemoveOrphanedDisplayAdEvents
    def run
      # Delete all DisplayAdEvents belonging to DisplayAds that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM display_ad_events
          WHERE display_ad_id NOT IN (SELECT id FROM display_ads);
        SQL
      )

      # Delete all DisplayAdEvents belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM display_ad_events
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
