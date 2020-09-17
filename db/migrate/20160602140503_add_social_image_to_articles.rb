class AddSocialImageToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :social_image, :string
  end
end
