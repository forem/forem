class AddIndexToArticlesCollectionId < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :articles, :collection_id, algorithm: :concurrently
  end
end
