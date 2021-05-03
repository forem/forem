class AddIndexOnArticlesCommentsCount < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    return if index_exists?(:articles, :comments_count)

    add_index :articles, :comments_count, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:articles, :comments_count)

    remove_index :articles, column: :comments_count, algorithm: :concurrently
  end
end
