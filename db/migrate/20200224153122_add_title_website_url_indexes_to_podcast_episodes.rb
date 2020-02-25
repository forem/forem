class AddTitleWebsiteUrlIndexesToPodcastEpisodes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :podcast_episodes, :title, algorithm: :concurrently
    add_index :podcast_episodes, :website_url, algorithm: :concurrently
  end
end
