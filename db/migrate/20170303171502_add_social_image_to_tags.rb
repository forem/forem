class AddSocialImageToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :social_image, :string
  end
end
