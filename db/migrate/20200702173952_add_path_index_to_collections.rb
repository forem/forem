class AddPathIndexToCollections < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    return if index_exists?(:collections, :path)

    add_index :collections, :path, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:collections, :path)

    remove_index :collections, column: :path, algorithm: :concurrently
  end
end
