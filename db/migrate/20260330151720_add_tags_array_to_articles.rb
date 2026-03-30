class AddTagsArrayToArticles < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    unless column_exists?(:articles, :tags_array)
      add_column :articles, :tags_array, :text, array: true, default: []
    end
    unless index_exists?(:articles, :tags_array)
      add_index :articles, :tags_array, using: :gin, algorithm: :concurrently, name: "index_articles_on_tags_array"
    end

    unless column_exists?(:display_ads, :tags_array)
      add_column :display_ads, :tags_array, :text, array: true, default: []
    end
    unless index_exists?(:display_ads, :tags_array)
      add_index :display_ads, :tags_array, using: :gin, algorithm: :concurrently, name: "index_display_ads_on_tags_array"
    end
  end

  def down
    remove_column :display_ads, :tags_array if column_exists?(:display_ads, :tags_array)
    remove_column :articles, :tags_array if column_exists?(:articles, :tags_array)
  end
end
