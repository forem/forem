class AddDarkNavImageToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :dark_nav_image, :string
  end
end
