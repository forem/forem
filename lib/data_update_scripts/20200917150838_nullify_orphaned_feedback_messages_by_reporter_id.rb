module DataUpdateScripts
  class NullifyOrphanedFeedbackMessagesByReporterId
    def run
      # Nullify all FeedbackMessages reporter_id belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          UPDATE feedback_messages
          SET reporter_id = NULL
          WHERE reporter_id IS NOT NULL
          AND reporter_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
