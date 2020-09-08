module DataUpdateScripts
  class RemoveOrphanedRatingVotesByArticle
    def run
      # Delete all RatingVotes belonging to Articles that don't exist anymore
      ActiveRecord::Base.connection.execute(
        <<~SQL,
          DELETE FROM rating_votes
          WHERE article_id NOT IN (SELECT id FROM articles);
        SQL
      )
    end
  end
end
