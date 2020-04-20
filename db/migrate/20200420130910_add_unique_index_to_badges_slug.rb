class AddUniqueIndexToBadgesSlug < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    return if index_exists?(:badges, :slug)

    add_index :badges, :slug, unique: true, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:badges, :slug)

    remove_index :badges, :slug
  end
end
