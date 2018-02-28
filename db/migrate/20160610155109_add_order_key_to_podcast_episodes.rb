class AddOrderKeyToPodcastEpisodes < ActiveRecord::Migration
  def change
    add_column :podcast_episodes, :order_key, :string
  end
end
