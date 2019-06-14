class AddUniqueIndexesToPodcasts < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :podcasts, :slug, unique: true, algorithm: :concurrently
    add_index :podcasts, :feed_url, unique: true, algorithm: :concurrently
  end
end
