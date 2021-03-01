class AddUniqueIndexToArticlesSlugUserId < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    unless index_exists?(:articles, %i[slug user_id], unique: true)
      add_index :articles, %i[slug user_id], unique: true, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:articles, %i[slug user_id], unique: true)
      remove_index :articles, column: %i[slug user_id], algorithm: :concurrently
    end
  end
end
