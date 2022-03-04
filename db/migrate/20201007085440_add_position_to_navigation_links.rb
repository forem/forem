class AddPositionToNavigationLinks < ActiveRecord::Migration[6.0]
  def change
    add_column :navigation_links, :position, :integer
  end
end
