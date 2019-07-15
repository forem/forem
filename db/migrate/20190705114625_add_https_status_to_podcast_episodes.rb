class AddHttpsStatusToPodcastEpisodes < ActiveRecord::Migration[5.2]
  class PodcastEpisode < ApplicationRecord; end

  def change
    add_column :podcast_episodes, :https, :boolean, default: true

    PodcastEpisode.where("media_url ILIKE ?", "http:/%").update_all(https: false)
  end
end
