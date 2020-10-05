class AddOrderToNavigationLinks < ActiveRecord::Migration[6.0]
  def change
    add_column :navigation_links, :order, :integer
  end
end
