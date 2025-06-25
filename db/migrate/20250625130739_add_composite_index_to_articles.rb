class AddCompositeIndexToArticles < ActiveRecord::Migration[7.0] # Or your Rails version
  disable_ddl_transaction!
  def change
    add_index :articles,
              [:published, :canonical_url],
              name: 'index_articles_on_published_and_canonical_url',
              algorithm: :concurrently
  end
end
