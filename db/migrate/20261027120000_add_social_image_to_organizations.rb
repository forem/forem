class AddSocialImageToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :social_image, :string
  end
end
