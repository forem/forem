module DataUpdateScripts
  class UpdatePublicReactionsCountFromPositiveReactionsCount
    def run
      # ActiveRecord::Base.connection.execute("UPDATE articles SET public_reactions_count = positive_reactions_count,
      # previous_public_reactions_count = previous_positive_reactions_count")
      # ActiveRecord::Base.connection.execute("UPDATE comments SET public_reactions_count = positive_reactions_count")
    end
  end
end
