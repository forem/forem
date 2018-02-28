class AddProcessedHtmlToPodcastEpisodes < ActiveRecord::Migration
  def change
    add_column :podcast_episodes, :processed_html, :text
  end
end
