class AddReachableToPodcastEpisodes < ActiveRecord::Migration[5.2]
  def change
    add_column :podcast_episodes, :reachable, :boolean, default: true
    add_column :podcast_episodes, :status_notice, :string
  end
end
