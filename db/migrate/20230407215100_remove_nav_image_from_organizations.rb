class RemoveNavImageFromOrganizations < ActiveRecord::Migration[7.0]
    def change
      safety_assured { remove_column :organizations, :nav_image, :string }
      safety_assured { remove_column :organizations, :dark_nav_image, :string }
    end
  end