class AddUniqueIndexesToPodcastEpisodes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :podcast_episodes, :media_url, unique: true, algorithm: :concurrently
    add_index :podcast_episodes, :guid, unique: true, algorithm: :concurrently
  end
end
