class AddSectionToNavigationLinks < ActiveRecord::Migration[6.1]
  def change
    add_column :navigation_links, :section, :integer, default: 0, null: false
  end
end
