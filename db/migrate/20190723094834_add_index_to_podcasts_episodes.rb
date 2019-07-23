class AddIndexToPodcastsEpisodes < ActiveRecord::Migration[5.2]
  def change
    add_index :podcast_episodes, :podcast_id
  end
end
