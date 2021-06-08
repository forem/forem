module Organizations
  class Delete
    def initialize(org)
      @org = org
      @article_ids = org.article_ids
    end

    def call
      delete_notifications
      org.destroy
      articles_sync
    end

    def self.call(...)
      new(...).call
    end

    private

    attr_reader :org, :article_ids

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

    def articles_sync
      # Syncs article cached organization
      Article.where(id: article_ids).update_all(cached_organization: nil)
    end
  end
end
