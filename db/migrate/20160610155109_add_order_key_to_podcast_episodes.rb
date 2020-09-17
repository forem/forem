class AddOrderKeyToPodcastEpisodes < ActiveRecord::Migration[4.2]
  def change
    add_column :podcast_episodes, :order_key, :string
  end
end
