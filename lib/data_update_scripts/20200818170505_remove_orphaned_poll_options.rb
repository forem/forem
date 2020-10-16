module DataUpdateScripts
  class RemoveOrphanedPollOptions
    def run
      # Delete all PollOptions belonging to Polls that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM poll_options
          WHERE poll_id NOT IN (SELECT id FROM polls);
        SQL
      )

      # Delete all PollOptions belonging to Polls that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM poll_options
          WHERE poll_id NOT IN (SELECT id FROM polls);
        SQL
      )
    end
  end
end
