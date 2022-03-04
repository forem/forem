class AddIndexToArticlesPublicReactionsCounts < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    if !index_exists?(:articles, :public_reactions_count)
      add_index :articles, :public_reactions_count, order: { public_reactions_count: :desc }, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:articles, :public_reactions_count)
      remove_index :articles, column: :public_reactions_count, algorithm: :concurrently
    end
  end
end
