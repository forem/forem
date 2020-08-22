module DataUpdateScripts
  class RemoveOrphanedNotificationsByOrganization
    def run
      # Delete all Notifications belonging to Organizations that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM notifications
          WHERE organization_id NOT IN (SELECT id FROM organization_id);
        SQL
      )
    end
  end
end
