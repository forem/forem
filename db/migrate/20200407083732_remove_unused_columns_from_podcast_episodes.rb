class RemoveUnusedColumnsFromPodcastEpisodes < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :podcast_episodes, :deepgram_id_code, :string
      remove_column :podcast_episodes, :featured, :boolean, default: true
      remove_column :podcast_episodes, :featured_number, :integer
      remove_column :podcast_episodes, :order_key, :string
    end
  end
end
