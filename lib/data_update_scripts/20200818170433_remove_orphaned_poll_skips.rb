module DataUpdateScripts
  class RemoveOrphanedPollSkips
    def run
      # Delete all PollSkips belonging to Polls that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM poll_skips
          WHERE poll_id NOT IN (SELECT id FROM polls);
        SQL
      )

      # Delete all PollSkips belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM poll_skips
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
