class AddIndexToTrendsTagId < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    return if index_exists?(:trends, :tag_id)

    add_index :trends, :tag_id, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:trends, :tag_id)

    remove_index :trends, :tag_id, algorithm: :concurrently
  end
end
