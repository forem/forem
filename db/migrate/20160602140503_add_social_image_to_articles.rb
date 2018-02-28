class AddSocialImageToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :social_image, :string
  end
end
