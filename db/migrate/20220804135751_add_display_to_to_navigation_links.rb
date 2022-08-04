class AddDisplayToToNavigationLinks < ActiveRecord::Migration[7.0]
  def change
    add_column :navigation_links, :display_to, :integer, default: 0, null: false
  end
end
