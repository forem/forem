class AddPublishedPartialIndexToPodcasts < ActiveRecord::Migration[6.1]
    disable_ddl_transaction!

  def up
    return if index_exists?(:podcasts, :published)

    add_index :podcasts,
              :published,
              where: "published = true",
              algorithm: :concurrently
  end

  def down
    return unless index_exists?(:podcasts, :published)

    remove_index :podcasts,
                 column: :published,
                 algorithm: :concurrently
  end
end
