class AddProcessedHtmlToPodcastEpisodes < ActiveRecord::Migration[4.2]
  def change
    add_column :podcast_episodes, :processed_html, :text
  end
end
