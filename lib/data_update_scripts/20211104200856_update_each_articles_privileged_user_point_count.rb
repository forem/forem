module DataUpdateScripts
  class UpdateEachArticlesPrivilegedUserPointCount
    def run
      # This code is "idempotent" in that it's calculating and caching a value stored elsewhere.
      Article.find_in_batches do |articles|
        articles.each do |article|
          # Given that we have a default of 0, don't update if we
          # don't have any reactions.
          next unless article.reactions.privileged_category.exists?

          article.update_column(:privileged_users_reaction_points_sum,
                                article.reactions.privileged_category.sum(:points))
        end
      end
    end
  end
end
