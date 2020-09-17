class AddDeepgramIdCodeToPodcastEpisodes < ActiveRecord::Migration[4.2]
  def change
    add_column :podcast_episodes, :deepgram_id_code, :string
  end
end
