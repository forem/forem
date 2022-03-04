class AddBodyToPodcastEpisodes < ActiveRecord::Migration[4.2]
  def change
    add_column :podcast_episodes, :body, :text
  end
end
