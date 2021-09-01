class DropDurationInSecondsFromPodcastEpisodes < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :podcast_episodes, :duration_in_seconds, :integer
    end
  end
end
