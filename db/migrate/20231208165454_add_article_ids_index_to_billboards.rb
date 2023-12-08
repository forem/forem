class AddArticleIdsIndexToBillboards < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :display_ads, :preferred_article_ids, using: 'gin', algorithm: :concurrently
  end
end
