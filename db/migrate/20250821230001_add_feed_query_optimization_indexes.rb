class AddFeedQueryOptimizationIndexes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      execute "SET statement_timeout = 0;"

      # Clean up after previous removal in case it was left behind
      remove_index :reactions,
                   name: 'index_reactions_on_reactable_and_user_for_moderation',
                   if_exists: true,
                   algorithm: :concurrently


      # Add index for featured articles (used in with_at_least_home_feed_minimum_score)
      # This is different from the moderation indexes and specific to feed queries
      add_index :articles, 
                [:featured, :published, :published_at], 
                name: 'index_articles_on_featured_published_published_at',
                where: "published = true",
                order: { published_at: :desc },
                algorithm: :concurrently
      
      # Add index for type_of filtering (full_post vs other types)
      add_index :articles, 
                [:type_of, :published, :score, :published_at], 
                name: 'index_articles_on_type_of_published_score_published_at',
                where: "published = true",
                order: { published_at: :desc },
                algorithm: :concurrently
      
      # Add index for user_id filtering (for blocked users)
      add_index :articles, 
                [:user_id, :published, :score, :published_at], 
                name: 'index_articles_on_user_id_published_score_published_at',
                where: "published = true",
                order: { published_at: :desc },
                algorithm: :concurrently
    end
  end
end
