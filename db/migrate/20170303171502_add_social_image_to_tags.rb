class AddSocialImageToTags < ActiveRecord::Migration
  def change
    add_column :tags, :social_image, :string
  end
end
