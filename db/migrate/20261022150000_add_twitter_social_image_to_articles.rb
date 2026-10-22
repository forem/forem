class AddTwitterSocialImageToArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :articles, :twitter_social_image, :string
  end
end
