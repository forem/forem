class AddTagsArrayToTaggables < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :articles, :tags_array, :text, array: true, default: [] unless column_exists?(:articles, :tags_array)
    add_index :articles, :tags_array, using: :gin, algorithm: :concurrently unless index_exists?(:articles, :tags_array)

    add_column :classified_listings, :tags_array, :text, array: true, default: [] unless column_exists?(:classified_listings, :tags_array)
    add_index :classified_listings, :tags_array, using: :gin, algorithm: :concurrently unless index_exists?(:classified_listings, :tags_array)

    add_column :display_ads, :tags_array, :text, array: true, default: [] unless column_exists?(:display_ads, :tags_array)
    add_index :display_ads, :tags_array, using: :gin, algorithm: :concurrently unless index_exists?(:display_ads, :tags_array)
  end
end
