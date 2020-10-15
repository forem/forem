class ValidateAddMissingForeignKeysToPodcastEpisodes < ActiveRecord::Migration[6.0]
  def change
    validate_foreign_key :podcast_episodes, :podcasts
  end
end
