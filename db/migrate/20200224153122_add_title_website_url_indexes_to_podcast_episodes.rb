class AddTitleWebsiteUrlIndexesToPodcastEpisodes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:podcast_episodes, :title)
      add_index :podcast_episodes, :title, algorithm: :concurrently
    end

    unless index_exists?(:podcast_episodes, :website_url)
      add_index :podcast_episodes, :website_url, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:podcast_episodes, :title)
      remove_index :podcast_episodes, column: :title, algorithm: :concurrently
    end

    if index_exists?(:podcast_episodes, :website_url)
      remove_index :podcast_episodes, column: :website_url, algorithm: :concurrently
    end
  end
end
