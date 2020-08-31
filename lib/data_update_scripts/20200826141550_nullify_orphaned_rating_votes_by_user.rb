module DataUpdateScripts
  class NullifyOrphanedRatingVotesByUser
    def run
      # Nullify all RatingVotes belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          UPDATE rating_votes
          SET user_id = NULL
          WHERE user_id IS NOT NULL
          AND user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
