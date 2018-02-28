class AddDeepgramIdCodeToPodcastEpisodes < ActiveRecord::Migration
  def change
    add_column :podcast_episodes, :deepgram_id_code, :string
  end
end
