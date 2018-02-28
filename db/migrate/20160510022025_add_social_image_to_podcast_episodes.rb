class AddSocialImageToPodcastEpisodes < ActiveRecord::Migration
  def change
    add_column :podcast_episodes, :social_image, :string
  end
end
