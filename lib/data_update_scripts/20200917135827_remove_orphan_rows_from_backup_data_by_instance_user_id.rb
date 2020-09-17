module DataUpdateScripts
  class RemoveOrphanRowsFromBackupDataByInstanceUserId
    def run
      # Delete all BackupData rows belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM backup_data
          WHERE instance_user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
