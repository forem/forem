class AddImageToNavigationLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :navigation_links, :image, :string
  end
end
