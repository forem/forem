class AddTitleWebsiteUrlIndexesToPodcastEpisodes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  include IndexMigrationHelpers

  def up
    add_index_if_missing(:podcast_episodes, :title, algorithm: :concurrently)
    add_index_if_missing(:podcast_episodes, :website_url, algorithm: :concurrently)
  end

  def down
    remove_index_if_exists(:podcast_episodes, column: :title, algorithm: :concurrently)
    remove_index_if_exists(:podcast_episodes, column: :website_url, algorithm: :concurrently)
  end
end
