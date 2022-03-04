class AddMissingForeignKeysToPodcastEpisodes < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :podcast_episodes, :podcasts, column: :podcast_id, on_delete: :cascade, validate: false
  end
end
