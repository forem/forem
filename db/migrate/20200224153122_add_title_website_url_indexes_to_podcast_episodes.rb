class AddTitleWebsiteUrlIndexesToPodcastEpisodes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  include IndexMigrationHelpers

  def change
    add_index_if_missing(:podcast_episodes, :title, algorithm: :concurrently)
    add_index_if_missing(:podcast_episodes, :website_url, algorithm: :concurrently)
  end
end
