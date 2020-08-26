module DataUpdateScripts
  class RemoveOrphanedRatingVotesByUser
    def run
      # Delete all RatingVotes belonging to Users that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM rating_votes
          WHERE user_id NOT IN (SELECT id FROM users);
        SQL
      )
    end
  end
end
