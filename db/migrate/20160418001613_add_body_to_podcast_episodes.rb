class AddBodyToPodcastEpisodes < ActiveRecord::Migration
  def change
    add_column :podcast_episodes, :body, :text
  end
end
