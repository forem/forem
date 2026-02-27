module DataUpdateScripts
  class FixNegativeReactionCounters
    def run
      # Fix negative public_reactions_count on Articles
      # This resynchronizes the counter with the actual count of public reactions
      ActiveRecord::Base.logger.info("Fixing negative public_reactions_count on Articles...")
      
      negative_articles_count = Article.where("public_reactions_count < 0").count
      if negative_articles_count > 0
        ActiveRecord::Base.logger.info("Found #{negative_articles_count} articles with negative counts")
        
        Article.where("public_reactions_count < 0").find_in_batches(batch_size: 100) do |articles|
          articles.each do |article|
            old_count = article.public_reactions_count
            article.sync_reactions_count
            article.reload
            new_count = article.public_reactions_count
            
            ActiveRecord::Base.logger.info(
              "Fixed Article #{article.id}: #{old_count} -> #{new_count}"
            )
          end
        end
      else
        ActiveRecord::Base.logger.info("No articles with negative counts found")
      end

      # Fix negative public_reactions_count on Comments
      ActiveRecord::Base.logger.info("Fixing negative public_reactions_count on Comments...")
      
      negative_comments_count = Comment.where("public_reactions_count < 0").count
      if negative_comments_count > 0
        ActiveRecord::Base.logger.info("Found #{negative_comments_count} comments with negative counts")
        
        Comment.where("public_reactions_count < 0").find_in_batches(batch_size: 100) do |comments|
          comments.each do |comment|
            old_count = comment.public_reactions_count
            comment.sync_reactions_count
            comment.reload
            new_count = comment.public_reactions_count
            
            ActiveRecord::Base.logger.info(
              "Fixed Comment #{comment.id}: #{old_count} -> #{new_count}"
            )
          end
        end
      else
        ActiveRecord::Base.logger.info("No comments with negative counts found")
      end

      ActiveRecord::Base.logger.info("Negative reactions count fix complete!")
    end
  end
end
