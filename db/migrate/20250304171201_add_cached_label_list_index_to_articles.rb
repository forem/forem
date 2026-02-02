class AddCachedLabelListIndexToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :articles, :cached_label_list, using: 'gin', algorithm: :concurrently
  end
end
