class AddIndexToPodcastsEpisodes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :podcast_episodes, :podcast_id, algorithm: :concurrently
  end
end
