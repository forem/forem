module DataUpdateScripts
  class UpdatePublicReactionCountsAgain
    def run
      ActiveRecord::Base.connection.execute("UPDATE articles SET public_reactions_count = positive_reactions_count, previous_public_reactions_count = previous_positive_reactions_count WHERE id < #{Article.count / 2}")
      ActiveRecord::Base.connection.execute("UPDATE articles SET public_reactions_count = positive_reactions_count, previous_public_reactions_count = previous_positive_reactions_count WHERE id > #{Article.count / 2}")
      ActiveRecord::Base.connection.execute("UPDATE comments SET public_reactions_count = positive_reactions_count WHERE id < #{Comment.count / 2}")
      ActiveRecord::Base.connection.execute("UPDATE comments SET public_reactions_count = positive_reactions_count WHERE id > #{Comment.count / 2}")
    end
  end
end
