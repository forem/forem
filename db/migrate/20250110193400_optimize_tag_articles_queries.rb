class OptimizeTagArticlesQueries < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  
  def change
    # Add composite index for better tag article queries
    # This helps with the cached_tagged_with_any queries that use regex on cached_tag_list
    add_index :articles, [:cached_tag_list, :published_at, :score], 
              name: "index_articles_on_cached_tag_list_published_at_score",
              where: "published = true"
    
    # Add index for hotness_score ordering which is used in default tag feed
    add_index :articles, [:hotness_score, :published_at], 
              name: "index_articles_on_hotness_score_published_at",
              where: "published = true"
    
    # Add index for tag pages with subforem filtering
    add_index :articles, [:cached_tag_list, :subforem_id, :published_at], 
              name: "index_articles_on_cached_tag_subforem_published",
              where: "published = true"
  end
end