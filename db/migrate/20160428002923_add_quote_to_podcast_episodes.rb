class AddQuoteToPodcastEpisodes < ActiveRecord::Migration
  def change
    add_column :podcast_episodes, :quote, :text
  end
end
