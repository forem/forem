module DataUpdateScripts
  class RemoveOrphanedPollVotes
    def run
      # Delete all PollVotes belonging to Polls that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM poll_votes
          WHERE poll_id NOT IN (SELECT id FROM polls);
        SQL
      )

      # Delete all PollVotes belonging to PollOptions that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM poll_votes
          WHERE poll_option_id NOT IN (SELECT id FROM poll_options);
        SQL
      )

      # Delete all PollVotes belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          DELETE FROM poll_votes
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
