class AddUniqueIndexToArticlesCanonicalUrl < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    unless index_exists?(:articles, :canonical_url, unique: true)
      add_index :articles, :canonical_url, unique: true, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:articles, :canonical_url, unique: true)
      remove_index :articles, column: :canonical_url, algorithm: :concurrently
    end
  end
end
