class AddSocialImageToProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :profiles, :social_image, :string
  end
end
