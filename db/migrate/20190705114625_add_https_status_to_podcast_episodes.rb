class AddHttpsStatusToPodcastEpisodes < ActiveRecord::Migration[5.2]
  def change
    add_column :podcast_episodes, :https, :boolean, default: true

    PodcastEpisode.where("media_url like ?", "http:/%").update_all(https: false)
  end
end
