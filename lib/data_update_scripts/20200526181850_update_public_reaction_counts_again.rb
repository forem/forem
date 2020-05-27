module DataUpdateScripts
  class UpdatePublicReactionCountsAgain
    def run
      article_count = Article.count
      comment_count = Comment.count
      ActiveRecord::Base.connection.execute("UPDATE articles SET public_reactions_count = positive_reactions_count, previous_public_reactions_count = previous_positive_reactions_count WHERE id <= #{article_count / 2}")
      ActiveRecord::Base.connection.execute("UPDATE articles SET public_reactions_count = positive_reactions_count, previous_public_reactions_count = previous_positive_reactions_count WHERE id > #{article_count / 2}")
      ActiveRecord::Base.connection.execute("UPDATE comments SET public_reactions_count = positive_reactions_count WHERE id <= #{comment_count / 2}")
      ActiveRecord::Base.connection.execute("UPDATE comments SET public_reactions_count = positive_reactions_count WHERE id > #{comment_count / 2}")
    end
  end
end
