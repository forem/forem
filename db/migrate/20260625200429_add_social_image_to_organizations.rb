class AddSocialImageToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :social_image, :string
  end
end
