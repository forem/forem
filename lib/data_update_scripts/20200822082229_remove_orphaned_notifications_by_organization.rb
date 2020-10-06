module DataUpdateScripts
  class RemoveOrphanedNotificationsByOrganization
    def run
      # Delete all Notifications belonging to Organizations that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM notifications
          WHERE organization_id NOT IN (SELECT id FROM organizations);
        SQL
      )
    end
  end
end
