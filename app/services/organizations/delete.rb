module Organizations
  class Delete
    def initialize(org)
      @org = org
    end

    def call
      delete_notifications
      org.destroy
    end

    def self.call(...)
      new(...).call
    end

    private

    attr_reader :org

    def delete_notifications
      sql = <<-SQL.squish
        DELETE FROM notifications
        WHERE notifications.id IN (
          SELECT notifications.id
          FROM notifications
          WHERE organization_id = ?
        )
      SQL

      notification_sql = Notification.sanitize_sql([sql, org.id])

      BulkSqlDelete.delete_in_batches(notification_sql)
    end
  end
end
