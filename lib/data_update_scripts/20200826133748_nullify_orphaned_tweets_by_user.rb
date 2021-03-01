module DataUpdateScripts
  class NullifyOrphanedTweetsByUser
    def run
      # Nullify user_id for all Tweets linked to a non existing User
      ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          UPDATE tweets
          SET user_id = NULL
          WHERE user_id IS NOT NULL
          AND user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
