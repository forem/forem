class AddSocialImageToPodcastEpisodes < ActiveRecord::Migration[4.2]
  def change
    add_column :podcast_episodes, :social_image, :string
  end
end
