class AddUniqueIndexToArticlesCanonicalUrlWherePublished < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    if index_exists?(:articles, :canonical_url, unique: true)
      remove_index :articles, column: :canonical_url, unique: true, algorithm: :concurrently
    end

    add_index :articles, :canonical_url, unique: true, where: "published is true", algorithm: :concurrently
  end

  def down
    if index_exists?(:articles, :canonical_url, unique: true, where: "published is true")
      remove_index :articles, :canonical_url, unique: true, where: "published is true", algorithm: :concurrently
    end

    add_index :articles, column: :canonical_url, unique: true, algorithm: :concurrently
  end
end
